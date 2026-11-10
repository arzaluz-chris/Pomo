// PomoWatch/ViewModels/WatchTimerViewModel.swift

import Foundation
import SwiftUI
import Combine
import WatchKit
import WidgetKit

@MainActor
class WatchTimerViewModel: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var isActive: Bool = false
    @Published var currentType: TimerType = .work
    @Published var completedSessions: Int = 0

    // Duration settings
    @AppStorage(Constants.UserDefaults.workDuration) private var workDurationMinutes: Int = Constants.Defaults.workDuration / 60
    @AppStorage(Constants.UserDefaults.shortBreakDuration) private var shortBreakDurationMinutes: Int = Constants.Defaults.shortBreakDuration / 60
    @AppStorage(Constants.UserDefaults.longBreakDuration) private var longBreakDurationMinutes: Int = Constants.Defaults.longBreakDuration / 60
    @AppStorage(Constants.UserDefaults.sessionsUntilLongBreak) private var sessionsUntilLongBreak: Int = Constants.Defaults.sessionsUntilLongBreak

    // Persistent timer state (prefixed to avoid collisions with iOS)
    @AppStorage("watch_savedTimerEndTime") private var savedEndTime: Double = 0
    @AppStorage("watch_savedTimerIsActive") private var savedIsActive: Bool = false
    @AppStorage("watch_savedTimerType") private var savedTimerType: String = TimerType.work.rawValue
    @AppStorage("watch_savedCompletedSessions") private var savedCompletedSessions: Int = 0
    @AppStorage("watch_lastSessionDate") private var lastSessionDate: Double = 0
    @AppStorage("watch_savedTimeRemaining") private var savedTimeRemaining: Int = 0
    @AppStorage("watch_isPaused") private var isPaused: Bool = false
    @AppStorage("watch_totalSessionDuration") private var totalSessionDuration: Int = 0

    // Sync timestamp
    @AppStorage("watch_lastActionTimestamp") private var lastActionTimestamp: Double = 0

    // Identity and start of the current session, shared with the iPhone. Persisted so a
    // completed session is still recorded after watchOS terminates the app. Either device
    // may record it; the iPhone store drops the duplicate by session ID.
    @AppStorage("watch_savedSessionID") private var sessionID: String = ""
    @AppStorage("watch_savedSessionStartTime") private var savedSessionStartTime: Double = 0
    // Mirrors the iPhone "Notifications" setting (synced with the duration settings)
    @AppStorage("watch_notificationsEnabled") private var notificationsEnabled: Bool = true
    private var sessionStartTime: Date? {
        get { savedSessionStartTime > 0 ? Date(timeIntervalSince1970: savedSessionStartTime) : nil }
        set { savedSessionStartTime = newValue?.timeIntervalSince1970 ?? 0 }
    }

    private var timer: Timer?
    private let hapticService = WatchHapticService()
    private let notificationService = WatchNotificationService()
    private var midnightTimer: Timer?

    // Settings change tracking
    private var previousWorkDuration: Int = 0
    private var previousShortBreakDuration: Int = 0
    private var previousLongBreakDuration: Int = 0
    private var isUpdatingSettings = false

    private var cancellables = Set<AnyCancellable>()

    var progress: Double {
        let total = totalSessionDuration > 0 ? Double(totalSessionDuration) : Double(getDurationForType(currentType))
        guard total > 0 else { return 0 }
        let progressValue = 1.0 - (Double(timeRemaining) / total)
        return max(0, min(1, progressValue))
    }

    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var buttonTitle: String {
        isActive ? NSLocalizedString("PAUSE", comment: "Pause button title") : NSLocalizedString("START", comment: "Start button title")
    }

    init() {
        previousWorkDuration = workDurationMinutes
        previousShortBreakDuration = shortBreakDurationMinutes
        previousLongBreakDuration = longBreakDurationMinutes

        restoreState()
        setupNotificationObservers()
        setupMidnightTimer()
        setupWatchConnectivityCallbacks()
    }

    deinit {
        midnightTimer?.invalidate()
    }

    // MARK: - Midnight Reset

    private func setupMidnightTimer() {
        midnightTimer?.invalidate()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let midnight = calendar.startOfDay(for: tomorrow)
        let timeUntilMidnight = midnight.timeIntervalSince(Date())

        midnightTimer = Timer.scheduledTimer(withTimeInterval: timeUntilMidnight, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.resetSessionsAtMidnight()
                self?.setupMidnightTimer()
            }
        }
    }

    private func resetSessionsAtMidnight() {
        completedSessions = 0
        savedCompletedSessions = 0
        lastSessionDate = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
    }

    // MARK: - State Restoration

    private func restoreState() {
        completedSessions = savedCompletedSessions
        resetSessionsIfNeeded()

        if let type = TimerType(rawValue: savedTimerType) {
            currentType = type
        }

        if isPaused && savedTimeRemaining > 0 {
            timeRemaining = savedTimeRemaining
            isActive = false
            if totalSessionDuration == 0 {
                totalSessionDuration = getDurationForType(currentType)
            }
        } else if savedTimeRemaining > 0 && !savedIsActive {
            timeRemaining = savedTimeRemaining
            if totalSessionDuration == 0 {
                totalSessionDuration = getDurationForType(currentType)
            }
        } else if savedIsActive && savedEndTime > Date().timeIntervalSince1970 {
            let remaining = Int(savedEndTime - Date().timeIntervalSince1970)
            if remaining > 0 {
                timeRemaining = remaining
                isActive = true
                if totalSessionDuration == 0 {
                    totalSessionDuration = getDurationForType(currentType)
                }
                startTimerCounting()
                scheduleCompletionAlert()
            } else {
                handleTimerExpired()
            }
        } else if savedIsActive {
            // Session ended while the app was not running
            handleTimerExpired()
        } else {
            resetToInitialState()
        }
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: WKApplication.willResignActiveNotification)
            .sink { [weak self] _ in self?.handleAppGoingToBackground() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: WKApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.handleAppComingToForeground() }
            .store(in: &cancellables)

        // Settings change detection
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let userDefaults = notification.object as? UserDefaults,
                   userDefaults == UserDefaults.standard {
                    self.handleSettingsChange()
                }
            }
            .store(in: &cancellables)
    }

    private func handleSettingsChange() {
        guard !isUpdatingSettings else { return }

        let workChanged = previousWorkDuration != workDurationMinutes
        let shortBreakChanged = previousShortBreakDuration != shortBreakDurationMinutes
        let longBreakChanged = previousLongBreakDuration != longBreakDurationMinutes

        if (workChanged || shortBreakChanged || longBreakChanged) && !isActive && !isPaused {
            isUpdatingSettings = true
            previousWorkDuration = workDurationMinutes
            previousShortBreakDuration = shortBreakDurationMinutes
            previousLongBreakDuration = longBreakDurationMinutes

            timeRemaining = getDurationForType(currentType)
            totalSessionDuration = 0

            if savedTimeRemaining > 0 && !isPaused {
                savedTimeRemaining = 0
            }

            isUpdatingSettings = false
        }
    }

    // MARK: - Background Handling

    private func handleAppGoingToBackground() {
        guard isActive else {
            if timeRemaining > 0 {
                savedTimeRemaining = timeRemaining
            }
            return
        }

        savedEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
        savedIsActive = true
        savedTimerType = currentType.rawValue
        savedCompletedSessions = completedSessions
        savedTimeRemaining = 0
    }

    private func handleAppComingToForeground() {
        resetSessionsIfNeeded()
        notificationService.clearDelivered()

        if !savedIsActive && savedTimeRemaining > 0 {
            timeRemaining = savedTimeRemaining
            return
        }

        guard savedIsActive else { return }

        let now = Date().timeIntervalSince1970
        if savedEndTime > now {
            timeRemaining = Int(savedEndTime - now)
            if !isActive {
                isActive = true
                startTimerCounting()
            }
        } else {
            handleTimerExpired()
        }
    }

    private func handleTimerExpired() {
        // Record the session at its real end time, not when the app noticed it
        let endDate = savedEndTime > 0 ? Date(timeIntervalSince1970: min(savedEndTime, Date().timeIntervalSince1970)) : Date()
        timeRemaining = 0
        savedTimeRemaining = 0
        isPaused = false
        sessionCompleted(wasSkipped: false, endDate: endDate)
    }

    // MARK: - Timer Controls

    func toggleTimer() {
        hapticService.playClick()
        if isActive {
            pauseTimer()
        } else {
            resetSessionsIfNeeded()
            startTimer()
        }
    }

    func resetTimer() {
        hapticService.playClick()

        if isActive {
            timer?.invalidate()
            timer = nil
            isActive = false
            savedIsActive = false
        }

        savedTimeRemaining = 0
        savedEndTime = 0
        isPaused = false
        sessionStartTime = nil
        totalSessionDuration = 0

        resetToInitialState()
        notificationService.cancelCompletion()
        updateComplications()
        lastActionTimestamp = Date().timeIntervalSince1970
        syncStateToPhone()
    }

    func skipSession() {
        guard isActive else { return }
        hapticService.playClick()
        isPaused = false
        sessionCompleted(wasSkipped: true)
    }

    func changeTimerType(to type: TimerType) {
        guard !isActive && type != currentType else { return }
        hapticService.playClick()
        currentType = type
        savedTimerType = type.rawValue
        savedTimeRemaining = 0
        isPaused = false
        totalSessionDuration = 0
        timeRemaining = getDurationForType(type)
    }

    func startTimer() {
        if isPaused && savedTimeRemaining > 0 {
            timeRemaining = savedTimeRemaining
            isPaused = false
            savedTimeRemaining = 0
        } else if savedTimeRemaining > 0 && !isPaused {
            timeRemaining = savedTimeRemaining
            savedTimeRemaining = 0
        }

        // New session: store its total length (resuming keeps the original one)
        if totalSessionDuration == 0 {
            totalSessionDuration = timeRemaining
        }

        isActive = true
        savedIsActive = true

        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        if sessionID.isEmpty {
            sessionID = UUID().uuidString
        }

        savedEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
        startTimerCounting()
        scheduleCompletionAlert()
        updateComplications()

        hapticService.playStart()
        lastActionTimestamp = Date().timeIntervalSince1970
        syncStateToPhone()
    }

    private func startTimerCounting() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in self.updateTimer() }
        }
    }

    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1

            // Update complications periodically
            if timeRemaining % 30 == 0 {
                updateComplications()
            }
        } else {
            sessionCompleted(wasSkipped: false)
        }
    }

    private func pauseTimer() {
        isActive = false
        savedIsActive = false
        savedEndTime = 0
        isPaused = true

        if timeRemaining > 0 {
            savedTimeRemaining = timeRemaining
        }

        timer?.invalidate()
        timer = nil
        notificationService.cancelCompletion()
        updateComplications()

        hapticService.playStop()
        lastActionTimestamp = Date().timeIntervalSince1970
        syncStateToPhone()
    }

    private func resetToInitialState() {
        timeRemaining = getDurationForType(currentType)
        totalSessionDuration = 0
        sessionStartTime = nil
        sessionID = ""
        savedEndTime = 0
        savedIsActive = false
        savedTimeRemaining = 0
        isPaused = false
    }

    // MARK: - Session Completion

    private func sessionCompleted(wasSkipped: Bool, endDate: Date = Date()) {
        // Capture the planned length before the state is cleared
        let plannedDuration = totalSessionDuration > 0 ? totalSessionDuration : getDurationForType(currentType)

        timer?.invalidate()
        timer = nil
        isActive = false
        savedIsActive = false
        savedTimeRemaining = 0
        isPaused = false
        totalSessionDuration = 0
        notificationService.cancelCompletion()

        if !wasSkipped {
            hapticService.playSessionComplete()
        } else {
            hapticService.playWarning()
        }

        // Save completed session and sync to iPhone
        if let startTime = sessionStartTime {
            let duration = max(0, plannedDuration - timeRemaining)
            let session = SessionSync(
                id: UUID(uuidString: sessionID) ?? UUID(),
                startDate: startTime,
                endDate: endDate,
                duration: duration,
                type: currentType,
                wasCompleted: !wasSkipped,
                originDevice: "Watch"
            )
            WatchConnectivityManager.shared.syncCompletedSession(session)
        }

        if currentType == .work && !wasSkipped {
            resetSessionsIfNeeded()
            completedSessions += 1
            savedCompletedSessions = completedSessions
        }

        moveToNextSessionType()
        resetToInitialState()
        updateComplications()

        lastActionTimestamp = Date().timeIntervalSince1970
        syncStateToPhone()
    }

    private func moveToNextSessionType() {
        switch currentType {
        case .work:
            if completedSessions > 0 && completedSessions % sessionsUntilLongBreak == 0 {
                currentType = .longBreak
            } else {
                currentType = .shortBreak
            }
        case .shortBreak, .longBreak:
            currentType = .work
        }
        savedTimerType = currentType.rawValue
    }

    private func resetSessionsIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        let lastDate = Date(timeIntervalSince1970: lastSessionDate)

        if lastSessionDate == 0 || !calendar.isDate(now, inSameDayAs: lastDate) {
            completedSessions = 0
            savedCompletedSessions = 0
        }

        lastSessionDate = calendar.startOfDay(for: now).timeIntervalSince1970
    }

    // MARK: - Complications

    private func updateComplications() {
        // Write state to the App Group so the complication extension (a separate process
        // with its own UserDefaults.standard) can read it
        let defaults = UserDefaults(suiteName: Constants.AppGroup.identifier) ?? .standard
        defaults.set(currentType.rawValue, forKey: Constants.WatchComplication.timerType)
        defaults.set(timeRemaining, forKey: Constants.WatchComplication.timeRemaining)
        defaults.set(isActive, forKey: Constants.WatchComplication.isActive)
        defaults.set(totalSessionDuration > 0 ? totalSessionDuration : getDurationForType(currentType),
                     forKey: Constants.WatchComplication.totalDuration)
        defaults.set(Date().timeIntervalSince1970 + Double(timeRemaining),
                     forKey: Constants.WatchComplication.endTime)

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Sync to iPhone

    private func syncStateToPhone() {
        let state = TimerStateSync(
            currentType: currentType,
            timeRemaining: timeRemaining,
            isActive: isActive,
            isPaused: isPaused,
            completedSessions: completedSessions,
            totalSessionDuration: totalSessionDuration,
            endTime: isActive ? savedEndTime : nil,
            sessionID: (isActive || isPaused) && !sessionID.isEmpty ? sessionID : nil,
            sessionStartDate: (isActive || isPaused) ? sessionStartTime?.timeIntervalSince1970 : nil
        )
        lastActionTimestamp = max(lastActionTimestamp, state.timestamp)
        WatchConnectivityManager.shared.syncTimerState(state)
    }

    private func scheduleCompletionAlert() {
        guard notificationsEnabled, savedEndTime > 0 else {
            notificationService.cancelCompletion()
            return
        }
        // The iPhone schedules the same alert with the same identifier so the system can
        // coordinate them instead of showing two
        notificationService.scheduleCompletion(for: currentType, at: Date(timeIntervalSince1970: savedEndTime))
    }

    // MARK: - Receive from iPhone

    private func setupWatchConnectivityCallbacks() {
        WatchConnectivityManager.shared.onSettingsReceived = { [weak self] settings in
            Task { @MainActor in
                self?.applyReceivedSettings(settings)
            }
        }

        WatchConnectivityManager.shared.onTimerStateReceived = { [weak self] state in
            Task { @MainActor in
                self?.applyReceivedTimerState(state)
            }
        }
    }

    private func applyReceivedSettings(_ settings: SettingsSync) {
        isUpdatingSettings = true

        workDurationMinutes = settings.workDuration
        shortBreakDurationMinutes = settings.shortBreakDuration
        longBreakDurationMinutes = settings.longBreakDuration
        sessionsUntilLongBreak = settings.sessionsUntilLongBreak
        if let enabled = settings.notificationsEnabled {
            notificationsEnabled = enabled
            if !enabled { notificationService.cancelCompletion() }
        }

        previousWorkDuration = settings.workDuration
        previousShortBreakDuration = settings.shortBreakDuration
        previousLongBreakDuration = settings.longBreakDuration

        // Update display if idle
        if !isActive && !isPaused {
            timeRemaining = getDurationForType(currentType)
            totalSessionDuration = 0
        }

        isUpdatingSettings = false
    }

    private func applyReceivedTimerState(_ state: TimerStateSync) {
        // Only apply if incoming timestamp is newer than our last action
        guard state.timestamp > lastActionTimestamp else { return }

        // Remember the newest state applied so an older message arriving late is ignored
        lastActionTimestamp = max(lastActionTimestamp, state.timestamp)

        // Stop current timer if running
        timer?.invalidate()
        timer = nil

        // Adopt the shared session identity so this device can record the session if it is
        // the first to notice it ended
        if let remoteID = state.sessionID {
            sessionID = remoteID
        }
        if let remoteStart = state.sessionStartDate {
            savedSessionStartTime = remoteStart
        }

        currentType = state.timerType
        savedTimerType = state.currentType
        completedSessions = state.completedSessions
        savedCompletedSessions = state.completedSessions
        totalSessionDuration = state.totalSessionDuration
        isPaused = state.isPaused

        if state.isActive, let endTime = state.endTime {
            let remaining = Int(endTime - Date().timeIntervalSince1970)
            if remaining > 0 {
                timeRemaining = remaining
                isActive = true
                savedIsActive = true
                savedEndTime = endTime
                savedTimeRemaining = 0
                startTimerCounting()
                scheduleCompletionAlert()
            } else {
                savedEndTime = endTime
                savedIsActive = true
                handleTimerExpired()
            }
        } else if state.isPaused {
            timeRemaining = state.timeRemaining
            isActive = false
            savedIsActive = false
            savedEndTime = 0
            savedTimeRemaining = state.timeRemaining
            notificationService.cancelCompletion()
        } else {
            isActive = false
            savedIsActive = false
            savedEndTime = 0
            savedTimeRemaining = 0
            sessionStartTime = nil
            sessionID = ""
            timeRemaining = getDurationForType(state.timerType)
            totalSessionDuration = 0
            notificationService.cancelCompletion()
        }

        updateComplications()
    }

    // MARK: - Helpers

    private func getDurationForType(_ type: TimerType) -> Int {
        switch type {
        case .work:
            return workDurationMinutes * 60
        case .shortBreak:
            return shortBreakDurationMinutes * 60
        case .longBreak:
            return longBreakDurationMinutes * 60
        }
    }
}
