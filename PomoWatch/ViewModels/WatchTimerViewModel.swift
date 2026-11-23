// PomoWatch/ViewModels/WatchTimerViewModel.swift

import Foundation
import SwiftUI
import Combine
import WatchKit
import WidgetKit

/// Apple Watch timer: a thin layer over `PomodoroEngine` (shared with the iPhone) that
/// persists the state and turns changes into effects (alert, haptics, complications,
/// iPhone sync).
@MainActor
final class WatchTimerViewModel: ObservableObject {
    @Published private(set) var state = PomodoroState()
    @Published private(set) var now = Date()

    // Duration settings (synced with the iPhone)
    @AppStorage(Constants.UserDefaults.workDuration) private var workDurationMinutes: Int = Constants.Defaults.workDuration / 60
    @AppStorage(Constants.UserDefaults.shortBreakDuration) private var shortBreakDurationMinutes: Int = Constants.Defaults.shortBreakDuration / 60
    @AppStorage(Constants.UserDefaults.longBreakDuration) private var longBreakDurationMinutes: Int = Constants.Defaults.longBreakDuration / 60
    @AppStorage(Constants.UserDefaults.sessionsUntilLongBreak) private var sessionsUntilLongBreak: Int = Constants.Defaults.sessionsUntilLongBreak
    // Mirrors the iPhone "Notifications" setting
    @AppStorage("watch_notificationsEnabled") private var notificationsEnabled: Bool = true

    private let store = TimerStateStore.appGroup(key: "watchPomodoroState")
    private let hapticService = WatchHapticService()
    private let notificationService = WatchNotificationService()

    private var ticker: Timer?
    private var midnightTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Derived values used by the views

    var settings: PomodoroSettings {
        PomodoroSettings(
            workMinutes: workDurationMinutes,
            shortBreakMinutes: shortBreakDurationMinutes,
            longBreakMinutes: longBreakDurationMinutes,
            sessionsUntilLongBreak: sessionsUntilLongBreak
        )
    }

    var timeRemaining: Int { state.remaining(at: now, settings: settings) }
    var isActive: Bool { state.isRunning }
    var isPaused: Bool { state.isPaused }
    var currentType: TimerType { state.type }
    var completedSessions: Int { state.completedSessions(on: now) }
    var progress: Double { state.progress(at: now, settings: settings) }

    var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    var buttonTitle: String {
        isActive ? NSLocalizedString("PAUSE", comment: "Pause button title") : NSLocalizedString("START", comment: "Start button title")
    }

    // MARK: - Init

    init() {
        if let saved = store.load() {
            state = saved
        } else if let legacy = PomodoroState.migratedFromLegacyKeys(in: .standard, prefix: "watch_", settings: settings, now: Date()) {
            state = legacy
            store.save(legacy)
            PomodoroState.removeLegacyKeys(from: .standard, prefix: "watch_")
        }

        #if DEBUG
        // Sample state for screenshots: launch with -PomoDemoData YES
        if UserDefaults.standard.bool(forKey: "PomoDemoData") {
            let now = Date()
            var demo = PomodoroState()
            demo.phase = .running
            demo.totalDuration = 1500
            demo.endDate = now.addingTimeInterval(1143)
            demo.sessionStart = now.addingTimeInterval(-357)
            demo.sessionID = UUID().uuidString
            demo.completedToday = 3
            demo.day = Calendar.current.startOfDay(for: now)
            demo.updatedAt = now
            state = demo
            notificationsEnabled = false
        }
        #endif

        setupObservers()
        setupWatchConnectivityCallbacks()
        scheduleMidnightRefresh()

        commit(PomodoroEngine.reconcile(state, settings: settings, now: Date()), origin: .clock, forceEffects: true)
    }

    deinit {
        ticker?.invalidate()
        midnightTimer?.invalidate()
    }

    // MARK: - User actions

    func toggleTimer() {
        hapticService.playClick()
        let now = Date()
        reconcile(now: now)
        if state.isRunning {
            commit(PomodoroTransition(PomodoroEngine.pause(state, settings: settings, now: now)), origin: .local)
            hapticService.playStop()
        } else {
            commit(PomodoroTransition(PomodoroEngine.start(state, settings: settings, now: now)), origin: .local)
            hapticService.playStart()
        }
    }

    func resetTimer() {
        hapticService.playClick()
        commit(PomodoroTransition(PomodoroEngine.reset(state, now: Date())), origin: .local)
    }

    func skipSession() {
        guard !state.isIdle else { return }
        hapticService.playClick()
        let now = Date()
        reconcile(now: now)
        guard !state.isIdle else { return }
        commit(PomodoroEngine.skip(state, settings: settings, now: now), origin: .local)
        hapticService.playWarning()
    }

    func changeTimerType(to type: TimerType) {
        guard state.isIdle, type != state.type else { return }
        hapticService.playClick()
        commit(PomodoroTransition(PomodoroEngine.select(type, in: state, now: Date())), origin: .local)
    }

    // MARK: - State changes and effects

    private enum Origin {
        case local, remote, clock
    }

    private func reconcile(now: Date = Date()) {
        let transition = PomodoroEngine.reconcile(state, settings: settings, now: now)
        if transition.state != state || transition.record != nil {
            commit(transition, origin: .clock)
        }
    }

    private func commit(_ transition: PomodoroTransition, origin: Origin, forceEffects: Bool = false) {
        let old = state
        let new = transition.state
        if new != old {
            state = new
            store.save(new)
        }
        now = Date()

        if let record = transition.record {
            // The iPhone stores statistics; it drops the duplicate if it recorded it too
            WatchConnectivityManager.shared.syncCompletedSession(SessionSync(
                id: UUID(uuidString: record.id) ?? UUID(),
                startDate: record.start,
                endDate: record.end,
                duration: record.duration,
                type: record.type,
                wasCompleted: record.wasCompleted,
                originDevice: "Watch"
            ))
            if record.wasCompleted, WKApplication.shared().applicationState == .active {
                hapticService.playSessionComplete()
            }
        }

        let timingChanged = forceEffects || old.phase != new.phase || old.endDate != new.endDate || old.type != new.type
        if timingChanged {
            scheduleCompletionAlert()
        }

        updateTicker()
        if new != old || forceEffects {
            updateComplications()
        }

        if origin != .remote && new != old {
            WatchConnectivityManager.shared.syncTimerState(TimerStateSync(new, settings: settings, now: now))
        }
    }

    private func scheduleCompletionAlert() {
        guard notificationsEnabled, state.isRunning, let endDate = state.endDate else {
            notificationService.cancelCompletion()
            return
        }
        // The iPhone schedules the same alert with the same identifier so the system can
        // coordinate them instead of showing two
        notificationService.scheduleCompletion(for: state.type, at: endDate)
    }

    // MARK: - Clock

    private func updateTicker() {
        guard state.isRunning else {
            ticker?.invalidate()
            ticker = nil
            return
        }
        guard ticker == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        now = Date()
        if let endDate = state.endDate, state.isRunning, endDate <= now {
            reconcile(now: now)
        }
    }

    private func scheduleMidnightRefresh() {
        midnightTimer?.invalidate()
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else { return }
        let timer = Timer(fire: tomorrow.addingTimeInterval(1), interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.reconcile()
                self?.scheduleMidnightRefresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        midnightTimer = timer
    }

    // MARK: - App lifecycle

    private func setupObservers() {
        NotificationCenter.default.publisher(for: WKApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.notificationService.clearDelivered()
                self.reconcile()
            }
            .store(in: &cancellables)

        // Duration settings edited on the Watch change the idle duration shown
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.objectWillChange.send()
                if self.state.isIdle { self.updateComplications() }
            }
            .store(in: &cancellables)
    }

    // MARK: - Complications

    private func updateComplications() {
        // Written to the App Group: the complication extension is a separate process with
        // its own UserDefaults.standard
        let defaults = UserDefaults(suiteName: Constants.AppGroup.identifier) ?? .standard
        let now = Date()
        defaults.set(state.type.rawValue, forKey: Constants.WatchComplication.timerType)
        defaults.set(state.remaining(at: now, settings: settings), forKey: Constants.WatchComplication.timeRemaining)
        defaults.set(state.isRunning, forKey: Constants.WatchComplication.isActive)
        defaults.set(state.plannedDuration(settings: settings), forKey: Constants.WatchComplication.totalDuration)
        defaults.set(state.endDate?.timeIntervalSince1970 ?? 0, forKey: Constants.WatchComplication.endTime)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - iPhone

    private func setupWatchConnectivityCallbacks() {
        WatchConnectivityManager.shared.onSettingsReceived = { [weak self] settings in
            Task { @MainActor in self?.applyReceivedSettings(settings) }
        }
        WatchConnectivityManager.shared.onTimerStateReceived = { [weak self] message in
            Task { @MainActor in self?.applyRemote(message) }
        }
    }

    private func applyReceivedSettings(_ settings: SettingsSync) {
        workDurationMinutes = settings.workDuration
        shortBreakDurationMinutes = settings.shortBreakDuration
        longBreakDurationMinutes = settings.longBreakDuration
        sessionsUntilLongBreak = settings.sessionsUntilLongBreak
        if let enabled = settings.notificationsEnabled, enabled != notificationsEnabled {
            notificationsEnabled = enabled
            scheduleCompletionAlert()
        }
        if state.isIdle { updateComplications() }
    }

    private func applyRemote(_ message: TimerStateSync) {
        let now = Date()
        // Record a session that already ended here before the remote state replaces it
        reconcile(now: now)

        let remote = message.pomodoroState(settings: settings, now: now)
        guard remote.updatedAt > state.updatedAt else { return }
        commit(PomodoroEngine.reconcile(remote, settings: settings, now: now), origin: .remote)
    }
}
