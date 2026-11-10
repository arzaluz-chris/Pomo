// Shared/Engine/TimerStateStore.swift

import Foundation

/// Persists the Pomodoro state as a single JSON value, normally in the App Group so
/// extensions (widgets, complications, intents) read the same state as the app.
struct TimerStateStore {
    let defaults: UserDefaults
    let key: String

    static let appGroupKey = "pomodoroState"

    init(defaults: UserDefaults, key: String = TimerStateStore.appGroupKey) {
        self.defaults = defaults
        self.key = key
    }

    /// Store shared through the App Group (falls back to standard defaults if the
    /// group container is unavailable, e.g. in a misconfigured test host).
    static func appGroup(key: String = TimerStateStore.appGroupKey) -> TimerStateStore {
        TimerStateStore(defaults: UserDefaults(suiteName: Constants.AppGroup.identifier) ?? .standard, key: key)
    }

    func load() -> PomodoroState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PomodoroState.self, from: data)
    }

    func save(_ state: PomodoroState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }
}

// MARK: - Migration from the 3.x per-key storage

extension PomodoroState {
    /// Rebuilds the state saved by Pomo 3.x, which stored each field under its own
    /// UserDefaults key (prefixed with `watch_` on Apple Watch). Returns nil when there
    /// is nothing to migrate.
    static func migratedFromLegacyKeys(in defaults: UserDefaults, prefix: String,
                                       settings: PomodoroSettings, now: Date) -> PomodoroState? {
        func key(_ name: String) -> String { prefix + name }

        let hasLegacyData = defaults.object(forKey: key("savedTimerType")) != nil
            || defaults.object(forKey: key("savedTimerIsActive")) != nil
        guard hasLegacyData else { return nil }

        var state = PomodoroState()
        state.type = TimerType(rawValue: defaults.string(forKey: key("savedTimerType")) ?? "") ?? .work
        state.completedToday = defaults.integer(forKey: key("savedCompletedSessions"))
        let lastDay = defaults.double(forKey: key("lastSessionDate"))
        state.day = lastDay > 0 ? Date(timeIntervalSince1970: lastDay) : nil

        let total = defaults.integer(forKey: key("totalSessionDuration"))
        let start = defaults.double(forKey: key("savedSessionStartTime"))
        let sessionID = defaults.string(forKey: key("savedSessionID")) ?? ""
        let isActive = defaults.bool(forKey: key("savedTimerIsActive"))
        let isPaused = defaults.bool(forKey: key("isPaused"))
        let endTime = defaults.double(forKey: key("savedTimerEndTime"))
        let savedRemaining = defaults.integer(forKey: key("savedTimeRemaining"))

        if isActive, endTime > 0 {
            state.phase = .running
            state.endDate = Date(timeIntervalSince1970: endTime)
        } else if isPaused, savedRemaining > 0 {
            state.phase = .paused
            state.pausedRemaining = savedRemaining
        }

        if state.phase != .idle {
            state.totalDuration = total > 0 ? total : settings.duration(for: state.type)
            state.sessionStart = start > 0 ? Date(timeIntervalSince1970: start) : nil
            state.sessionID = sessionID.isEmpty ? nil : sessionID
        }
        state.updatedAt = now
        return state
    }

    /// Removes the 3.x keys once they have been migrated.
    static func removeLegacyKeys(from defaults: UserDefaults, prefix: String) {
        for name in ["savedTimerEndTime", "savedTimerIsActive", "savedTimerType", "savedCompletedSessions",
                     "lastSessionDate", "savedTimeRemaining", "isPaused", "totalSessionDuration",
                     "savedSessionStartTime", "savedSessionID"] {
            defaults.removeObject(forKey: prefix + name)
        }
    }
}
