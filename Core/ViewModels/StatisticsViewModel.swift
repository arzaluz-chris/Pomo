// StatisticsViewModel.swift

import Foundation
import SwiftUI

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var todayPomodoros: Int = 0
    @Published var todayMinutes: Int = 0
    @Published var weeklyData: [DailyStats] = []
    @Published var currentStreak: Int = 0
    
    let dataService = DataService()
    
    var todayTimeString: String {
        let hours = todayMinutes / 60
        let minutes = todayMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "0 min"
        }
    }
    
    func loadData() async {
        await loadTodayStats()
        await loadWeeklyStats()
        calculateStreak()
    }
    
    private func loadTodayStats() async {
        let sessions = await dataService.fetchTodaySessions()
        
        // Debug
        print("DEBUG - Sesiones de hoy: \(sessions.count)")
        
        let workSessions = sessions.filter { session in
            session.timerType == .work && session.wasCompleted
        }
        
        todayPomodoros = workSessions.count
        
        // Calcular tiempo total de TODAS las sesiones (no solo work)
        var totalSeconds = 0
        for session in sessions {
            print("DEBUG - Sesión: tipo=\(session.type), duración=\(session.duration)s, completada=\(session.wasCompleted)")
            totalSeconds += session.duration
        }
        
        todayMinutes = totalSeconds / 60
        print("DEBUG - Tiempo total hoy: \(todayMinutes) minutos")
    }
    
    private func loadWeeklyStats() async {
        let sessions = await dataService.fetchWeeklySessions()
        let calendar = Calendar.current
        
        // Crear array con los últimos 7 días
        var dailyStats: [DailyStats] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let daySessions = sessions.filter { session in
                session.startDate >= startOfDay && session.startDate < endOfDay &&
                session.timerType == .work && session.wasCompleted
            }
            
            dailyStats.append(DailyStats(date: date, pomodoros: daySessions.count))
        }
        
        weeklyData = dailyStats.reversed()
    }
    
    private func calculateStreak() {
        // Implementación simplificada para el MVP
        currentStreak = 0
        
        if todayPomodoros > 0 {
            currentStreak = 1
        }
    }
}
