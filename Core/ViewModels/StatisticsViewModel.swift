// Core/ViewModels/StatisticsViewModel.swift

import Foundation
import SwiftUI

@MainActor
class StatisticsViewModel: ObservableObject {
    /// Completed focus (work) sessions today.
    @Published var todayPomodoros: Int = 0
    /// Minutes spent in focus sessions today.
    @Published var todayMinutes: Int = 0
    @Published var weeklyData: [DailyStats] = []
    @Published var currentStreak: Int = 0

    let dataService = DataService()
    private let calendar = Calendar.current

    var todayTimeString: String {
        let hours = todayMinutes / 60
        let minutes = todayMinutes % 60

        if hours > 0 {
            return String(localized: "\(hours)h \(minutes)min")
        } else if minutes > 0 {
            return String(localized: "\(minutes) min")
        } else {
            return String(localized: "0 min")
        }
    }

    func loadData() async {
        let now = Date()
        let sessions = dataService.fetchSamples()

        let today = StatsCalculator.dayStats(for: now, sessions: sessions, calendar: calendar)
        todayPomodoros = today.pomodoros
        todayMinutes = today.focusSeconds / 60

        weeklyData = StatsCalculator.lastDays(7, endingOn: now, sessions: sessions, calendar: calendar)
            .map { DailyStats(date: $0.day, pomodoros: $0.pomodoros) }

        currentStreak = StatsCalculator.streak(endingOn: now, sessions: sessions, calendar: calendar)

        dataService.publishSnapshot(now: now)
    }
}
