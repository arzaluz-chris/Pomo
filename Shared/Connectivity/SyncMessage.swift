// Shared/Connectivity/SyncMessage.swift

import Foundation

// MARK: - Settings Sync (via updateApplicationContext)

struct SettingsSync: Codable {
    let workDuration: Int          // in minutes
    let shortBreakDuration: Int    // in minutes
    let longBreakDuration: Int     // in minutes
    let sessionsUntilLongBreak: Int
    let timestamp: TimeInterval
    // Optional so older app versions on the other device can still decode the message
    let notificationsEnabled: Bool?

    init(workDuration: Int, shortBreakDuration: Int, longBreakDuration: Int, sessionsUntilLongBreak: Int,
         notificationsEnabled: Bool? = nil) {
        self.workDuration = workDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.sessionsUntilLongBreak = sessionsUntilLongBreak
        self.timestamp = Date().timeIntervalSince1970
        self.notificationsEnabled = notificationsEnabled
    }

    func toDictionary() -> [String: Any] {
        return [
            Constants.WatchConnectivity.settingsKey: (try? JSONEncoder().encode(self)) ?? Data()
        ]
    }

    static func from(dictionary: [String: Any]) -> SettingsSync? {
        guard let data = dictionary[Constants.WatchConnectivity.settingsKey] as? Data else { return nil }
        return try? JSONDecoder().decode(SettingsSync.self, from: data)
    }
}

// MARK: - Timer State Sync (via updateApplicationContext + sendMessage)

struct TimerStateSync: Codable {
    let currentType: String        // TimerType.rawValue
    let timeRemaining: Int         // seconds
    let isActive: Bool
    let isPaused: Bool
    let completedSessions: Int
    let totalSessionDuration: Int  // seconds
    let endTime: TimeInterval?     // absolute end time for running timers
    let timestamp: TimeInterval    // for conflict resolution (last action wins)
    // Identity of the running/paused session, shared by both devices so either one can
    // record it when it ends and the iPhone can drop the duplicate. Optional for
    // compatibility with older app versions.
    let sessionID: String?
    let sessionStartDate: TimeInterval?
    // Full engine state (4.0+). Receivers prefer it; the flat fields above stay filled
    // so an older app version on the other device keeps working.
    let state: PomodoroState?

    init(currentType: TimerType, timeRemaining: Int, isActive: Bool, isPaused: Bool,
         completedSessions: Int, totalSessionDuration: Int, endTime: TimeInterval?,
         sessionID: String? = nil, sessionStartDate: TimeInterval? = nil, state: PomodoroState? = nil) {
        self.currentType = currentType.rawValue
        self.timeRemaining = timeRemaining
        self.isActive = isActive
        self.isPaused = isPaused
        self.completedSessions = completedSessions
        self.totalSessionDuration = totalSessionDuration
        self.endTime = endTime
        self.timestamp = Date().timeIntervalSince1970
        self.sessionID = sessionID
        self.sessionStartDate = sessionStartDate
        self.state = state
    }

    /// Message for an engine state.
    init(_ state: PomodoroState, settings: PomodoroSettings, now: Date = Date()) {
        self.currentType = state.type.rawValue
        self.timeRemaining = state.remaining(at: now, settings: settings)
        self.isActive = state.isRunning
        self.isPaused = state.isPaused
        self.completedSessions = state.completedSessions(on: now)
        self.totalSessionDuration = state.totalDuration
        self.endTime = state.endDate?.timeIntervalSince1970
        self.timestamp = state.updatedAt.timeIntervalSince1970
        self.sessionID = state.sessionID
        self.sessionStartDate = state.sessionStart?.timeIntervalSince1970
        self.state = state
    }

    /// Engine state carried by the message, rebuilt from the flat fields when the sender
    /// is an older app version.
    func pomodoroState(settings: PomodoroSettings, now: Date = Date()) -> PomodoroState {
        if let state { return state }
        var rebuilt = PomodoroState()
        rebuilt.type = timerType
        rebuilt.completedToday = completedSessions
        rebuilt.day = Calendar.current.startOfDay(for: now)
        rebuilt.updatedAt = Date(timeIntervalSince1970: timestamp)
        if isActive, let endTime {
            rebuilt.phase = .running
            rebuilt.endDate = Date(timeIntervalSince1970: endTime)
        } else if isPaused {
            rebuilt.phase = .paused
            rebuilt.pausedRemaining = timeRemaining
        }
        if rebuilt.phase != .idle {
            rebuilt.totalDuration = totalSessionDuration > 0 ? totalSessionDuration : settings.duration(for: timerType)
            rebuilt.sessionID = sessionID
            rebuilt.sessionStart = sessionStartDate.map { Date(timeIntervalSince1970: $0) }
        }
        return rebuilt
    }

    var timerType: TimerType {
        TimerType(rawValue: currentType) ?? .work
    }

    func toDictionary() -> [String: Any] {
        return [
            Constants.WatchConnectivity.timerStateKey: (try? JSONEncoder().encode(self)) ?? Data()
        ]
    }

    static func from(dictionary: [String: Any]) -> TimerStateSync? {
        guard let data = dictionary[Constants.WatchConnectivity.timerStateKey] as? Data else { return nil }
        return try? JSONDecoder().decode(TimerStateSync.self, from: data)
    }
}

// MARK: - Session Sync (via transferUserInfo with UUID dedup)

struct SessionSync: Codable {
    let id: UUID                   // for deduplication
    let startDate: Date
    let endDate: Date
    let duration: Int              // seconds
    let type: String               // TimerType.rawValue
    let wasCompleted: Bool
    let originDevice: String       // "iPhone" or "Watch"

    init(id: UUID = UUID(), startDate: Date, endDate: Date, duration: Int,
         type: TimerType, wasCompleted: Bool, originDevice: String) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.type = type.rawValue
        self.wasCompleted = wasCompleted
        self.originDevice = originDevice
    }

    var timerType: TimerType {
        TimerType(rawValue: type) ?? .work
    }

    func toDictionary() -> [String: Any] {
        return [
            Constants.WatchConnectivity.completedSessionKey: (try? JSONEncoder().encode(self)) ?? Data()
        ]
    }

    static func from(dictionary: [String: Any]) -> SessionSync? {
        guard let data = dictionary[Constants.WatchConnectivity.completedSessionKey] as? Data else { return nil }
        return try? JSONDecoder().decode(SessionSync.self, from: data)
    }
}
