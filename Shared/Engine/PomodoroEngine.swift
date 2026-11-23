// Shared/Engine/PomodoroEngine.swift
//
// Pure Pomodoro state machine shared by the iPhone app, the Watch app, the
// Live Activity intents and the widgets. Time is stored as absolute dates, never
// as a ticking counter, so the state stays correct while the app is suspended or
// terminated: the remaining time is always derived from `endDate` and "now".

import Foundation

// MARK: - Settings

struct PomodoroSettings: Codable, Equatable, Sendable {
    var workMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var sessionsUntilLongBreak: Int

    static let `default` = PomodoroSettings(
        workMinutes: 25,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        sessionsUntilLongBreak: 4
    )

    /// Session length in seconds (at least one minute).
    func duration(for type: TimerType) -> Int {
        let minutes: Int
        switch type {
        case .work: minutes = workMinutes
        case .shortBreak: minutes = shortBreakMinutes
        case .longBreak: minutes = longBreakMinutes
        }
        return max(1, minutes) * 60
    }
}

// MARK: - State

struct PomodoroState: Codable, Equatable, Sendable {
    enum Phase: String, Codable, Sendable {
        case idle
        case running
        case paused
    }

    var phase: Phase = .idle
    var type: TimerType = .work
    /// When the running session ends. Only set while running.
    var endDate: Date?
    /// Seconds left when the session was paused. Only set while paused.
    var pausedRemaining: Int?
    /// Planned length of the current session in seconds (0 when idle).
    var totalDuration: Int = 0
    /// Shared iPhone/Watch identity of the current session, used to avoid recording it twice.
    var sessionID: String?
    /// When the current session was first started.
    var sessionStart: Date?
    /// Work sessions completed on `day`.
    var completedToday: Int = 0
    /// Start of the day `completedToday` belongs to.
    var day: Date?
    /// Last change, used to resolve conflicts between devices (newest wins).
    var updatedAt: Date = .distantPast

    var isIdle: Bool { phase == .idle }
    var isRunning: Bool { phase == .running }
    var isPaused: Bool { phase == .paused }

    /// Seconds left, rounded up so a fresh 25 min session reads 25:00 and 0 means "done".
    func remaining(at now: Date, settings: PomodoroSettings) -> Int {
        switch phase {
        case .running:
            guard let endDate else { return 0 }
            return max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
        case .paused:
            return max(0, pausedRemaining ?? plannedDuration(settings: settings))
        case .idle:
            return settings.duration(for: type)
        }
    }

    /// Planned length of the current (or next) session in seconds.
    func plannedDuration(settings: PomodoroSettings) -> Int {
        totalDuration > 0 ? totalDuration : settings.duration(for: type)
    }

    /// 0...1 fraction of the session already elapsed.
    func progress(at now: Date, settings: PomodoroSettings) -> Double {
        let total = Double(plannedDuration(settings: settings))
        guard total > 0 else { return 0 }
        let elapsed = 1 - Double(remaining(at: now, settings: settings)) / total
        return min(1, max(0, elapsed))
    }

    /// Completed work sessions for the day containing `now`.
    func completedSessions(on now: Date, calendar: Calendar = .current) -> Int {
        guard let day, calendar.isDate(day, inSameDayAs: now) else { return 0 }
        return completedToday
    }
}

// MARK: - Results

/// A finished (or skipped) session to store in statistics.
struct CompletedSessionRecord: Equatable, Sendable {
    var id: String
    var start: Date
    var end: Date
    /// Focused seconds (pauses excluded).
    var duration: Int
    var type: TimerType
    var wasCompleted: Bool
}

struct PomodoroTransition: Equatable, Sendable {
    var state: PomodoroState
    var record: CompletedSessionRecord?

    init(_ state: PomodoroState, record: CompletedSessionRecord? = nil) {
        self.state = state
        self.record = record
    }
}

// MARK: - Engine

enum PomodoroEngine {

    /// Starts a new session, or resumes a paused one.
    static func start(_ state: PomodoroState, settings: PomodoroSettings, now: Date,
                      calendar: Calendar = .current) -> PomodoroState {
        var next = rollDay(state, now: now, calendar: calendar)
        guard next.phase != .running else { return next }

        let remaining: Int
        if next.phase == .paused {
            remaining = max(1, next.pausedRemaining ?? next.plannedDuration(settings: settings))
            if next.totalDuration == 0 { next.totalDuration = remaining }
        } else {
            remaining = settings.duration(for: next.type)
            next.totalDuration = remaining
        }

        next.phase = .running
        next.endDate = now.addingTimeInterval(TimeInterval(remaining))
        next.pausedRemaining = nil
        if next.sessionID == nil { next.sessionID = UUID().uuidString }
        if next.sessionStart == nil { next.sessionStart = now }
        next.updatedAt = now
        return next
    }

    /// Pauses a running session. Call `reconcile` first so an expired session completes instead.
    static func pause(_ state: PomodoroState, settings: PomodoroSettings, now: Date) -> PomodoroState {
        guard state.phase == .running else { return state }
        var next = state
        next.pausedRemaining = max(1, state.remaining(at: now, settings: settings))
        next.endDate = nil
        next.phase = .paused
        next.updatedAt = now
        return next
    }

    /// Discards the current session and returns to the start of the same session type.
    static func reset(_ state: PomodoroState, now: Date) -> PomodoroState {
        var next = state
        next.phase = .idle
        next.endDate = nil
        next.pausedRemaining = nil
        next.totalDuration = 0
        next.sessionID = nil
        next.sessionStart = nil
        next.updatedAt = now
        return next
    }

    /// Chooses the session type while idle.
    static func select(_ type: TimerType, in state: PomodoroState, now: Date) -> PomodoroState {
        guard state.phase == .idle, state.type != type else { return state }
        var next = reset(state, now: now)
        next.type = type
        return next
    }

    /// Abandons the running or paused session and moves to the next session type.
    /// The time already focused is recorded as an uncompleted session.
    static func skip(_ state: PomodoroState, settings: PomodoroSettings, now: Date,
                     calendar: Calendar = .current) -> PomodoroTransition {
        guard state.phase != .idle else { return PomodoroTransition(state) }

        let focused = state.plannedDuration(settings: settings) - state.remaining(at: now, settings: settings)
        let record = makeRecord(state, end: now, duration: focused, wasCompleted: false)

        var next = rollDay(state, now: now, calendar: calendar)
        next.type = nextType(after: state.type, completedToday: next.completedToday,
                             countedThisSession: false, settings: settings)
        next = reset(next, now: now)
        return PomodoroTransition(next, record: record)
    }

    /// Finishes the session at `endDate` (its scheduled end), counts it and moves on.
    static func complete(_ state: PomodoroState, settings: PomodoroSettings, at endDate: Date,
                         calendar: Calendar = .current) -> PomodoroTransition {
        guard state.phase != .idle else { return PomodoroTransition(state) }

        let record = makeRecord(state, end: endDate,
                                duration: state.plannedDuration(settings: settings), wasCompleted: true)

        var next = rollDay(state, now: endDate, calendar: calendar)
        if state.type == .work {
            next.completedToday += 1
        }
        next.type = nextType(after: state.type, completedToday: next.completedToday,
                             countedThisSession: true, settings: settings)
        next = reset(next, now: endDate)
        return PomodoroTransition(next, record: record)
    }

    /// Brings the state up to date with the clock: completes a session whose end date has
    /// passed (at that end date, not "now") and starts a new day's counter after midnight.
    static func reconcile(_ state: PomodoroState, settings: PomodoroSettings, now: Date,
                          calendar: Calendar = .current) -> PomodoroTransition {
        if state.phase == .running, let endDate = state.endDate, endDate <= now {
            let completed = complete(state, settings: settings, at: endDate, calendar: calendar)
            return PomodoroTransition(rollDay(completed.state, now: now, calendar: calendar),
                                      record: completed.record)
        }
        return PomodoroTransition(rollDay(state, now: now, calendar: calendar))
    }

    /// Resets the daily counter when `now` is on a different day than the stored one.
    static func rollDay(_ state: PomodoroState, now: Date, calendar: Calendar = .current) -> PomodoroState {
        if let day = state.day, calendar.isDate(day, inSameDayAs: now) { return state }
        var next = state
        // Never move the counter's day backwards (e.g. completing at an earlier end date)
        if let day = state.day, day > now { return state }
        next.completedToday = 0
        next.day = calendar.startOfDay(for: now)
        return next
    }

    /// Picks the state to keep when another device sends its state: newest change wins.
    static func merge(local: PomodoroState, remote: PomodoroState) -> PomodoroState {
        remote.updatedAt > local.updatedAt ? remote : local
    }

    // MARK: Helpers

    private static func nextType(after type: TimerType, completedToday: Int,
                                 countedThisSession: Bool, settings: PomodoroSettings) -> TimerType {
        switch type {
        case .work:
            let interval = max(1, settings.sessionsUntilLongBreak)
            if countedThisSession, completedToday > 0, completedToday % interval == 0 {
                return .longBreak
            }
            return .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }

    private static func makeRecord(_ state: PomodoroState, end: Date, duration: Int,
                                   wasCompleted: Bool) -> CompletedSessionRecord? {
        guard let start = state.sessionStart else { return nil }
        return CompletedSessionRecord(
            id: state.sessionID ?? UUID().uuidString,
            start: start,
            end: max(start, end),
            duration: max(0, duration),
            type: state.type,
            wasCompleted: wasCompleted
        )
    }
}
