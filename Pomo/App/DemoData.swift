// Pomo/App/DemoData.swift
//
// DEBUG only: realistic sample data for screenshots and design reviews.
// Launch with `-PomoDemoData YES` (optionally `-PomoDemoState running|paused|idle`).

#if DEBUG
import Foundation
import SwiftData

enum DemoData {
    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: "PomoDemoData") }

    @MainActor
    static func seed(into container: ModelContainer) {
        guard isEnabled else { return }
        let context = container.mainContext
        try? context.delete(model: TimerSession.self)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Pomodoros per day, oldest first (last value = today)
        let perDay = [4, 6, 3, 7, 5, 8, 3]
        for (offset, count) in perDay.enumerated() {
            guard let day = calendar.date(byAdding: .day, value: offset - (perDay.count - 1), to: today) else { continue }
            for index in 0..<count {
                let start = day.addingTimeInterval(TimeInterval(9 * 3600 + index * 1800))
                context.insert(TimerSession(startDate: start, endDate: start.addingTimeInterval(1500), duration: 1500,
                                            type: .work, wasCompleted: true, sessionID: UUID().uuidString))
                context.insert(TimerSession(startDate: start.addingTimeInterval(1500), endDate: start.addingTimeInterval(1800), duration: 300,
                                            type: .shortBreak, wasCompleted: true, sessionID: UUID().uuidString))
            }
        }
        try? context.save()

        // Timer state
        let now = Date()
        var state = PomodoroState()
        state.completedToday = perDay.last ?? 0
        state.day = today
        state.updatedAt = now
        switch UserDefaults.standard.string(forKey: "PomoDemoState") ?? "running" {
        case "paused":
            state.phase = .paused
            state.totalDuration = 1500
            state.pausedRemaining = 1105
            state.sessionStart = now.addingTimeInterval(-600)
            state.sessionID = UUID().uuidString
        case "idle":
            break
        default:
            state.phase = .running
            state.totalDuration = 1500
            state.endDate = now.addingTimeInterval(1145)
            state.sessionStart = now.addingTimeInterval(-355)
            state.sessionID = UUID().uuidString
        }
        TimerStateStore.appGroup().save(state)
    }
}
#endif
