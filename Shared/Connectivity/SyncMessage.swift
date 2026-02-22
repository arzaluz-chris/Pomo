// Shared/Connectivity/SyncMessage.swift

import Foundation

// MARK: - Settings Sync (via updateApplicationContext)

struct SettingsSync: Codable {
    let workDuration: Int          // in minutes
    let shortBreakDuration: Int    // in minutes
    let longBreakDuration: Int     // in minutes
    let sessionsUntilLongBreak: Int
    let timestamp: TimeInterval

    init(workDuration: Int, shortBreakDuration: Int, longBreakDuration: Int, sessionsUntilLongBreak: Int) {
        self.workDuration = workDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.sessionsUntilLongBreak = sessionsUntilLongBreak
        self.timestamp = Date().timeIntervalSince1970
    }

    func toDictionary() -> [String: Any] {
        return [
            Constants.WatchConnectivity.settingsKey: try! JSONEncoder().encode(self)
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

    init(currentType: TimerType, timeRemaining: Int, isActive: Bool, isPaused: Bool,
         completedSessions: Int, totalSessionDuration: Int, endTime: TimeInterval?) {
        self.currentType = currentType.rawValue
        self.timeRemaining = timeRemaining
        self.isActive = isActive
        self.isPaused = isPaused
        self.completedSessions = completedSessions
        self.totalSessionDuration = totalSessionDuration
        self.endTime = endTime
        self.timestamp = Date().timeIntervalSince1970
    }

    var timerType: TimerType {
        TimerType(rawValue: currentType) ?? .work
    }

    func toDictionary() -> [String: Any] {
        return [
            Constants.WatchConnectivity.timerStateKey: try! JSONEncoder().encode(self)
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
            Constants.WatchConnectivity.completedSessionKey: try! JSONEncoder().encode(self)
        ]
    }

    static func from(dictionary: [String: Any]) -> SessionSync? {
        guard let data = dictionary[Constants.WatchConnectivity.completedSessionKey] as? Data else { return nil }
        return try? JSONDecoder().decode(SessionSync.self, from: data)
    }
}
