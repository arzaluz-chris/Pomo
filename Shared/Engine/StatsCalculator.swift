// Shared/Engine/StatsCalculator.swift
//
// Statistics shown in the app and in the widgets, computed from recorded sessions.

import Foundation

/// Minimal view of a recorded session, independent of SwiftData.
struct SessionSample: Equatable, Sendable {
    var start: Date
    var duration: Int   // seconds focused
    var type: TimerType
    var wasCompleted: Bool
}

struct DayStats: Equatable, Sendable {
    var day: Date
    /// Completed work sessions.
    var pomodoros: Int
    /// Seconds spent in work sessions (completed or skipped).
    var focusSeconds: Int
}

/// Summary published to the App Group for widgets.
struct StatsSnapshot: Codable, Equatable, Sendable {
    var day: Date
    var pomodoros: Int
    var focusSeconds: Int
    var streak: Int

    static let appGroupKey = "statsSnapshot"

    static func load(from defaults: UserDefaults?) -> StatsSnapshot? {
        guard let data = defaults?.data(forKey: appGroupKey) else { return nil }
        return try? JSONDecoder().decode(StatsSnapshot.self, from: data)
    }

    func save(to defaults: UserDefaults?) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults?.set(data, forKey: Self.appGroupKey)
    }

    /// Values for `date`: a snapshot from an earlier day means nothing was done today yet.
    func values(on date: Date, calendar: Calendar = .current) -> (pomodoros: Int, focusSeconds: Int, streak: Int) {
        if calendar.isDate(day, inSameDayAs: date) {
            return (pomodoros, focusSeconds, streak)
        }
        // The streak survives until the end of the day after the last active day
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date))
        let streakAlive = yesterday.map { calendar.isDate(day, inSameDayAs: $0) } ?? false && pomodoros > 0
        return (0, 0, streakAlive ? streak : 0)
    }
}

enum StatsCalculator {
    static func dayStats(for day: Date, sessions: [SessionSample], calendar: Calendar = .current) -> DayStats {
        let start = calendar.startOfDay(for: day)
        let daySessions = sessions.filter { calendar.isDate($0.start, inSameDayAs: start) && $0.type == .work }
        return DayStats(
            day: start,
            pomodoros: daySessions.filter(\.wasCompleted).count,
            focusSeconds: daySessions.reduce(0) { $0 + max(0, $1.duration) }
        )
    }

    /// Stats for the `count` days ending on `today`, oldest first.
    static func lastDays(_ count: Int, endingOn today: Date, sessions: [SessionSample],
                         calendar: Calendar = .current) -> [DayStats] {
        (0..<max(0, count)).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: today))
                .map { dayStats(for: $0, sessions: sessions, calendar: calendar) }
        }
    }

    /// Consecutive days with at least one completed work session, counting back from today.
    /// A streak stays alive during a day with no session yet if it reached yesterday.
    static func streak(endingOn today: Date, sessions: [SessionSample], calendar: Calendar = .current) -> Int {
        let activeDays = Set(sessions
            .filter { $0.type == .work && $0.wasCompleted }
            .map { calendar.startOfDay(for: $0.start) })

        var day = calendar.startOfDay(for: today)
        if !activeDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  activeDays.contains(yesterday) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while activeDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    static func snapshot(on today: Date, sessions: [SessionSample], calendar: Calendar = .current) -> StatsSnapshot {
        let stats = dayStats(for: today, sessions: sessions, calendar: calendar)
        return StatsSnapshot(
            day: stats.day,
            pomodoros: stats.pomodoros,
            focusSeconds: stats.focusSeconds,
            streak: streak(endingOn: today, sessions: sessions, calendar: calendar)
        )
    }
}
