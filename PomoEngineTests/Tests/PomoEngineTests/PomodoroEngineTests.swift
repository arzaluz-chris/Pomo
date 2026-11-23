import XCTest
@testable import PomoEngine

final class PomodoroEngineTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Mexico_City")!
        return calendar
    }()
    private let settings = PomodoroSettings.default
    /// 2026-11-09 10:00 local
    private lazy var t0: Date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 10))!

    private func start(_ state: PomodoroState = PomodoroState(), at date: Date? = nil) -> PomodoroState {
        PomodoroEngine.start(state, settings: settings, now: date ?? t0, calendar: calendar)
    }

    // MARK: Start / remaining

    func testStartSetsEndDateAndSessionIdentity() {
        let state = start()
        XCTAssertEqual(state.phase, .running)
        XCTAssertEqual(state.endDate, t0.addingTimeInterval(25 * 60))
        XCTAssertEqual(state.totalDuration, 25 * 60)
        XCTAssertNotNil(state.sessionID)
        XCTAssertEqual(state.sessionStart, t0)
        XCTAssertEqual(state.remaining(at: t0, settings: settings), 25 * 60)
        XCTAssertEqual(state.remaining(at: t0.addingTimeInterval(0.4), settings: settings), 25 * 60)
        XCTAssertEqual(state.remaining(at: t0.addingTimeInterval(60), settings: settings), 24 * 60)
    }

    func testStartWhileRunningIsNoOp() {
        let state = start()
        XCTAssertEqual(start(state, at: t0.addingTimeInterval(30)), state)
    }

    func testIdleRemainingFollowsSettings() {
        let custom = PomodoroSettings(workMinutes: 50, shortBreakMinutes: 10, longBreakMinutes: 20, sessionsUntilLongBreak: 3)
        XCTAssertEqual(PomodoroState().remaining(at: t0, settings: custom), 50 * 60)
    }

    // MARK: Pause / resume

    func testPauseKeepsRemainingAndResumeKeepsTotalAndIdentity() {
        let running = start()
        let paused = PomodoroEngine.pause(running, settings: settings, now: t0.addingTimeInterval(10 * 60))
        XCTAssertEqual(paused.phase, .paused)
        XCTAssertEqual(paused.pausedRemaining, 15 * 60)
        XCTAssertNil(paused.endDate)

        // Remaining time doesn't move while paused
        XCTAssertEqual(paused.remaining(at: t0.addingTimeInterval(3600), settings: settings), 15 * 60)

        let resumeAt = t0.addingTimeInterval(20 * 60)
        let resumed = start(paused, at: resumeAt)
        XCTAssertEqual(resumed.phase, .running)
        XCTAssertEqual(resumed.endDate, resumeAt.addingTimeInterval(15 * 60))
        XCTAssertEqual(resumed.totalDuration, 25 * 60, "progress ring must keep the original length")
        XCTAssertEqual(resumed.sessionID, running.sessionID)
        XCTAssertEqual(resumed.sessionStart, running.sessionStart)
        XCTAssertEqual(resumed.progress(at: resumeAt, settings: settings), 0.4, accuracy: 0.001)
    }

    func testSettingsChangeDoesNotAffectRunningSession() {
        let running = start()
        let longer = PomodoroSettings(workMinutes: 50, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsUntilLongBreak: 4)
        XCTAssertEqual(running.remaining(at: t0, settings: longer), 25 * 60)
        XCTAssertEqual(running.plannedDuration(settings: longer), 25 * 60)
    }

    // MARK: Completion

    func testReconcileCompletesAtScheduledEndDate() {
        let running = start()
        let end = t0.addingTimeInterval(25 * 60)
        let result = PomodoroEngine.reconcile(running, settings: settings, now: end.addingTimeInterval(3 * 3600), calendar: calendar)

        XCTAssertEqual(result.state.phase, .idle)
        XCTAssertEqual(result.state.type, .shortBreak)
        XCTAssertEqual(result.state.completedToday, 1)
        XCTAssertNil(result.state.sessionID)
        XCTAssertEqual(result.state.updatedAt, end, "both devices completing independently must produce the same timestamp")

        let record = try! XCTUnwrap(result.record)
        XCTAssertEqual(record.id, running.sessionID)
        XCTAssertEqual(record.start, t0)
        XCTAssertEqual(record.end, end, "recorded at the real end, not when the app noticed")
        XCTAssertEqual(record.duration, 25 * 60)
        XCTAssertTrue(record.wasCompleted)
        XCTAssertEqual(record.type, .work)
    }

    func testReconcileBeforeEndDoesNothing() {
        let running = start()
        let result = PomodoroEngine.reconcile(running, settings: settings, now: t0.addingTimeInterval(60), calendar: calendar)
        XCTAssertEqual(result.state, running)
        XCTAssertNil(result.record)
    }

    func testLongBreakAfterConfiguredNumberOfWorkSessions() {
        var state = PomodoroState()
        var now = t0
        var types: [TimerType] = []
        for _ in 0..<8 {
            state = start(state, at: now)
            now = state.endDate!
            state = PomodoroEngine.reconcile(state, settings: settings, now: now, calendar: calendar).state
            types.append(state.type)
        }
        XCTAssertEqual(types, [.shortBreak, .work, .shortBreak, .work, .shortBreak, .work, .longBreak, .work])
        XCTAssertEqual(state.completedToday, 4)
    }

    func testBreakCompletionDoesNotCountAsPomodoro() {
        var state = PomodoroEngine.select(.shortBreak, in: PomodoroState(), now: t0)
        state = start(state)
        let result = PomodoroEngine.reconcile(state, settings: settings, now: state.endDate!, calendar: calendar)
        XCTAssertEqual(result.state.completedToday, 0)
        XCTAssertEqual(result.state.type, .work)
        XCTAssertEqual(result.record?.type, .shortBreak)
    }

    // MARK: Skip / reset / select

    func testSkipRecordsFocusedTimeAndMovesOnWithoutCounting() {
        let running = start()
        let result = PomodoroEngine.skip(running, settings: settings, now: t0.addingTimeInterval(10 * 60), calendar: calendar)
        XCTAssertEqual(result.state.phase, .idle)
        XCTAssertEqual(result.state.type, .shortBreak)
        XCTAssertEqual(result.state.completedToday, 0)
        XCTAssertEqual(result.record?.duration, 10 * 60)
        XCTAssertEqual(result.record?.wasCompleted, false)
    }

    func testSkipWhilePausedRecordsOnlyFocusedTime() {
        let paused = PomodoroEngine.pause(start(), settings: settings, now: t0.addingTimeInterval(5 * 60))
        let result = PomodoroEngine.skip(paused, settings: settings, now: t0.addingTimeInterval(2 * 3600), calendar: calendar)
        XCTAssertEqual(result.record?.duration, 5 * 60)
    }

    func testSkipIdleIsNoOp() {
        let result = PomodoroEngine.skip(PomodoroState(), settings: settings, now: t0, calendar: calendar)
        XCTAssertNil(result.record)
        XCTAssertEqual(result.state, PomodoroState())
    }

    func testResetKeepsTypeAndClearsSession() {
        var state = PomodoroEngine.select(.shortBreak, in: PomodoroState(), now: t0)
        state = start(state)
        let reset = PomodoroEngine.reset(state, now: t0.addingTimeInterval(30))
        XCTAssertEqual(reset.phase, .idle)
        XCTAssertEqual(reset.type, .shortBreak)
        XCTAssertNil(reset.sessionID)
        XCTAssertNil(reset.sessionStart)
        XCTAssertEqual(reset.totalDuration, 0)
    }

    func testSelectOnlyWhileIdle() {
        let running = start()
        XCTAssertEqual(PomodoroEngine.select(.shortBreak, in: running, now: t0), running)
    }

    // MARK: Days

    func testCounterResetsOnNewDay() {
        var state = start()
        state = PomodoroEngine.reconcile(state, settings: settings, now: state.endDate!, calendar: calendar).state
        XCTAssertEqual(state.completedToday, 1)

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: t0)!
        XCTAssertEqual(state.completedSessions(on: tomorrow, calendar: calendar), 0)
        let rolled = PomodoroEngine.reconcile(state, settings: settings, now: tomorrow, calendar: calendar).state
        XCTAssertEqual(rolled.completedToday, 0)
    }

    func testSessionCrossingMidnightCountsForTheDayItEnds() {
        let lateNight = calendar.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 23, minute: 50))!
        let running = start(at: lateNight)  // ends 00:15 on the 10th
        let nextMorning = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 8))!
        let result = PomodoroEngine.reconcile(running, settings: settings, now: nextMorning, calendar: calendar)
        XCTAssertEqual(result.state.completedToday, 1)
        XCTAssertEqual(result.state.day, calendar.startOfDay(for: nextMorning))
    }

    func testSessionFinishedYesterdayCountsForYesterdayOnly() {
        let lateNight = calendar.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 23, minute: 20))!
        let running = start(at: lateNight)
        let nextMorning = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 8))!
        let result = PomodoroEngine.reconcile(running, settings: settings, now: nextMorning, calendar: calendar)
        XCTAssertNotNil(result.record)
        XCTAssertEqual(result.state.completedToday, 0)
        XCTAssertEqual(result.state.day, calendar.startOfDay(for: nextMorning))
    }

    // MARK: Sync

    func testMergeKeepsNewest() {
        let local = start()
        let remote = PomodoroEngine.pause(local, settings: settings, now: t0.addingTimeInterval(60))
        XCTAssertEqual(PomodoroEngine.merge(local: local, remote: remote), remote)
        XCTAssertEqual(PomodoroEngine.merge(local: remote, remote: local), remote)
        XCTAssertEqual(PomodoroEngine.merge(local: remote, remote: remote), remote)
    }

    // MARK: Persistence

    func testStoreRoundTrip() {
        let defaults = UserDefaults(suiteName: "PomodoroEngineTests.\(UUID().uuidString)")!
        let store = TimerStateStore(defaults: defaults)
        XCTAssertNil(store.load())
        let state = start()
        store.save(state)
        XCTAssertEqual(store.load(), state)
    }

    func testLegacyMigrationRunningSession() {
        let defaults = UserDefaults(suiteName: "PomodoroEngineTests.\(UUID().uuidString)")!
        let end = t0.addingTimeInterval(600)
        defaults.set("work", forKey: "watch_savedTimerType")
        defaults.set(true, forKey: "watch_savedTimerIsActive")
        defaults.set(end.timeIntervalSince1970, forKey: "watch_savedTimerEndTime")
        defaults.set(1500, forKey: "watch_totalSessionDuration")
        defaults.set(2, forKey: "watch_savedCompletedSessions")
        defaults.set(calendar.startOfDay(for: t0).timeIntervalSince1970, forKey: "watch_lastSessionDate")

        let state = try! XCTUnwrap(PomodoroState.migratedFromLegacyKeys(in: defaults, prefix: "watch_", settings: settings, now: t0))
        XCTAssertEqual(state.phase, .running)
        XCTAssertEqual(state.endDate, end)
        XCTAssertEqual(state.totalDuration, 1500)
        XCTAssertEqual(state.completedToday, 2)

        PomodoroState.removeLegacyKeys(from: defaults, prefix: "watch_")
        XCTAssertNil(PomodoroState.migratedFromLegacyKeys(in: defaults, prefix: "watch_", settings: settings, now: t0))
    }

    func testLegacyMigrationPausedSession() {
        let defaults = UserDefaults(suiteName: "PomodoroEngineTests.\(UUID().uuidString)")!
        defaults.set("shortBreak", forKey: "savedTimerType")
        defaults.set(false, forKey: "savedTimerIsActive")
        defaults.set(true, forKey: "isPaused")
        defaults.set(120, forKey: "savedTimeRemaining")

        let state = try! XCTUnwrap(PomodoroState.migratedFromLegacyKeys(in: defaults, prefix: "", settings: settings, now: t0))
        XCTAssertEqual(state.phase, .paused)
        XCTAssertEqual(state.type, .shortBreak)
        XCTAssertEqual(state.pausedRemaining, 120)
        XCTAssertEqual(state.totalDuration, 5 * 60)
    }
}
