// Core/ViewModels/TimerViewModel.swift

import Foundation
import SwiftUI
import Combine
import UIKit
import SwiftData
import WidgetKit

/// iPhone timer: a thin layer over `PomodoroEngine` that persists the state in the App
/// Group and turns state changes into effects (alert, Live Activity, Watch sync,
/// statistics, haptics and sound).
@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var state = PomodoroState()
    /// Clock used to derive the remaining time; refreshed every second while running.
    @Published private(set) var now = Date()

    // Duration settings (edited in Settings, synced with Apple Watch)
    @AppStorage(Constants.UserDefaults.workDuration) private var workDurationMinutes: Int = Constants.Defaults.workDuration / 60
    @AppStorage(Constants.UserDefaults.shortBreakDuration) private var shortBreakDurationMinutes: Int = Constants.Defaults.shortBreakDuration / 60
    @AppStorage(Constants.UserDefaults.longBreakDuration) private var longBreakDurationMinutes: Int = Constants.Defaults.longBreakDuration / 60
    @AppStorage(Constants.UserDefaults.sessionsUntilLongBreak) private var sessionsUntilLongBreak: Int = Constants.Defaults.sessionsUntilLongBreak

    // Quick Actions (set by SceneDelegate)
    @AppStorage("shouldStartTimer") private var shouldStartTimer: Bool = false
    @AppStorage("quickActionTimerType") private var quickActionTimerType: String = ""

    let dataService = DataService()
    private let store = TimerStateStore.appGroup()
    private let soundService = SoundService()
    private let notificationService = NotificationService()
    private let reviewService = ReviewService.shared
    private let liveActivityManager = LiveActivityManager.shared

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()

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

    init(modelContainer: ModelContainer) {
        // Attach storage before restoring: a session that ended while the app was closed is
        // recorded while restoring
        dataService.setModelContext(modelContainer.mainContext)

        if let saved = store.load() {
            state = saved
        } else if let legacy = PomodoroState.migratedFromLegacyKeys(in: .standard, prefix: "", settings: settings, now: Date()) {
            state = legacy
            store.save(legacy)
            PomodoroState.removeLegacyKeys(from: .standard, prefix: "")
        }

        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()

        setupObservers()
        setupWatchConnectivityCallbacks()
        scheduleMidnightRefresh()

        // Catch up with the clock and re-apply effects (alert, Live Activity) for a session
        // that was running when the app was last terminated
        commit(PomodoroEngine.reconcile(state, settings: settings, now: Date()), origin: .clock, forceEffects: true)

        // Apply an action a Live Activity button stored while the app could not handle it
        checkForLiveActivityAction()
    }

    deinit {
        ticker?.invalidate()
        midnightTimer?.invalidate()
    }

    // MARK: - User actions

    func toggleTimer() {
        impactFeedback.impactOccurred()
        if isActive { pause() } else { start() }
    }

    func resetTimer() {
        selectionFeedback.selectionChanged()
        commit(PomodoroTransition(PomodoroEngine.reset(state, now: Date())), origin: .local, keepLiveActivity: true)
    }

    func skipSession() {
        guard !state.isIdle else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let now = Date()
        reconcile(now: now)
        guard !state.isIdle else { return }
        commit(PomodoroEngine.skip(state, settings: settings, now: now), origin: .local, keepLiveActivity: true)
        notificationFeedback.notificationOccurred(.warning)
    }

    func changeTimerType(to type: TimerType) {
        guard state.isIdle, type != state.type else { return }
        selectionFeedback.selectionChanged()
        commit(PomodoroTransition(PomodoroEngine.select(type, in: state, now: Date())), origin: .local)
    }

    private func start() {
        let now = Date()
        reconcile(now: now)
        commit(PomodoroTransition(PomodoroEngine.start(state, settings: settings, now: now)), origin: .local)
    }

    private func pause() {
        let now = Date()
        reconcile(now: now)
        guard state.isRunning else { return }
        commit(PomodoroTransition(PomodoroEngine.pause(state, settings: settings, now: now)), origin: .local)
    }

    /// Runs a Live Activity / Dynamic Island button action. Called from the intent's
    /// perform(), which the system runs in the app's process (relaunching it in the
    /// background if needed). Waits for the Live Activity update and the alert scheduling
    /// before returning, because the system may suspend the app right after.
    func perform(_ action: PomoTimerAction) async {
        switch action {
        case .play:
            if !isActive { start() }
        case .pause:
            if isActive { pause() }
        case .reset:
            resetTimer()
        case .skip:
            skipSession()
        case .startFocus:
            startNew(.work)
        case .startBreak:
            startNew(state.type == .longBreak ? .longBreak : .shortBreak)
        }
        await liveActivityManager.waitForPendingUpdates()
        await notificationService.waitForPendingWork()
    }

    // MARK: - State changes and effects

    private enum Origin {
        case local   // user action on this iPhone (app, Live Activity, Quick Action)
        case remote  // state received from Apple Watch
        case clock   // time passed (session ended, new day)
    }

    /// Completes a session whose end date has passed.
    private func reconcile(now: Date = Date()) {
        let transition = PomodoroEngine.reconcile(state, settings: settings, now: now)
        if transition.state != state || transition.record != nil {
            commit(transition, origin: .clock)
        }
    }

    private func commit(_ transition: PomodoroTransition, origin: Origin,
                        keepLiveActivity: Bool = false, forceEffects: Bool = false) {
        let old = state
        let new = transition.state
        if new != old {
            state = new
            store.save(new)
        }
        now = Date()

        if let record = transition.record {
            save(record)
            if record.wasCompleted {
                celebrateCompletion(of: record.type)
            }
        }

        let timingChanged = forceEffects || old.phase != new.phase || old.endDate != new.endDate || old.type != new.type

        // End-of-session alert
        if timingChanged {
            if new.isRunning, let endDate = new.endDate {
                notificationService.scheduleCompletion(for: new.type, at: endDate)
            } else {
                notificationService.cancelCompletion()
            }
        }

        // Live Activity
        if timingChanged || new.totalDuration != old.totalDuration {
            if new.isIdle && !keepLiveActivity {
                liveActivityManager.end()
            } else {
                liveActivityManager.show(new, settings: settings, now: now)
            }
        }

        updateTicker()

        // Control Center toggle and Home/Lock Screen widgets read the shared state
        if new.phase != old.phase || new.endDate != old.endDate || new.type != old.type {
            ControlCenter.shared.reloadControls(ofKind: Constants.Widgets.timerControlKind)
            WidgetCenter.shared.reloadTimelines(ofKind: Constants.Widgets.todayWidgetKind)
        }

        // Apple Watch
        if origin != .remote && new != old {
            WatchConnectivityManager.shared.syncTimerState(TimerStateSync(new, settings: settings, now: now))
        }
    }

    private func save(_ record: CompletedSessionRecord) {
        Task {
            await dataService.saveSession(
                startDate: record.start,
                endDate: record.end,
                duration: record.duration,
                type: record.type,
                wasCompleted: record.wasCompleted,
                sessionID: record.id
            )
        }
    }

    private func celebrateCompletion(of type: TimerType) {
        if UIApplication.shared.applicationState == .active {
            notificationFeedback.notificationOccurred(.success)
            if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
                soundService.playSound(for: type)
            }
        }
        if type == .work {
            reviewService.recordCompletedPomodoro()
        }
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
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        now = Date()
        guard state.isRunning else { return }
        if let endDate = state.endDate, endDate <= now {
            reconcile(now: now)
        } else if timeRemaining % 30 == 0 {
            // Keeps the minimal Dynamic Island progress ring moving
            liveActivityManager.show(state, settings: settings, now: now)
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
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.notificationService.clearDelivered()
                self.reconcile()
                self.checkForLiveActivityAction()
                self.checkForQuickAction()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.checkForQuickAction() }
            .store(in: &cancellables)

        // Settings edited elsewhere change the idle duration shown by the timer; Quick
        // Actions arrive as UserDefaults flags written by the scene delegate
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.checkForQuickAction()
            }
            .store(in: &cancellables)
    }

    private func checkForQuickAction() {
        guard shouldStartTimer, let type = TimerType(rawValue: quickActionTimerType) else { return }
        shouldStartTimer = false
        quickActionTimerType = ""
        startNew(type)
    }

    /// Discards the current session (if any) and starts a session of `type`.
    private func startNew(_ type: TimerType) {
        let now = Date()
        reconcile(now: now)
        if state.isRunning && state.type == type { return }
        var next = PomodoroEngine.reset(state, now: now)
        next.type = type
        next = PomodoroEngine.start(next, settings: settings, now: now)
        commit(PomodoroTransition(next), origin: .local)
    }

    /// Fallback for actions stored by an intent that ran outside the app's process.
    private func checkForLiveActivityAction() {
        let defaults = UserDefaults(suiteName: Constants.AppGroup.identifier)
        guard let actionString = defaults?.string(forKey: Constants.LiveActivity.pendingActionKey),
              let action = PomoTimerAction(rawValue: actionString) else { return }

        defaults?.removeObject(forKey: Constants.LiveActivity.pendingActionKey)
        defaults?.removeObject(forKey: Constants.LiveActivity.actionTimestampKey)

        Task { await perform(action) }
    }

    // MARK: - Apple Watch

    private func setupWatchConnectivityCallbacks() {
        WatchConnectivityManager.shared.onTimerStateReceived = { [weak self] message in
            Task { @MainActor in self?.applyRemote(message) }
        }
        WatchConnectivityManager.shared.onSessionReceived = { [weak self] session in
            Task { @MainActor in self?.applyReceivedSession(session) }
        }
        WatchConnectivityManager.shared.onSettingsReceived = { [weak self] settings in
            Task { @MainActor in self?.applyReceivedSettings(settings) }
        }
    }

    private func applyRemote(_ message: TimerStateSync) {
        let now = Date()
        // Record a session that already ended here before the remote state replaces it
        reconcile(now: now)

        let remote = message.pomodoroState(settings: settings, now: now)
        guard remote.updatedAt > state.updatedAt else { return }
        commit(PomodoroEngine.reconcile(remote, settings: settings, now: now), origin: .remote)
    }

    private func applyReceivedSession(_ session: SessionSync) {
        Task {
            await dataService.saveSession(
                startDate: session.startDate,
                endDate: session.endDate,
                duration: session.duration,
                type: session.timerType,
                wasCompleted: session.wasCompleted,
                sessionID: session.id.uuidString
            )
        }
    }

    private func applyReceivedSettings(_ settings: SettingsSync) {
        workDurationMinutes = settings.workDuration
        shortBreakDurationMinutes = settings.shortBreakDuration
        longBreakDurationMinutes = settings.longBreakDuration
        sessionsUntilLongBreak = settings.sessionsUntilLongBreak
    }
}
