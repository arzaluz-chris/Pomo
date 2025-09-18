// Core/ViewModels/StatisticsViewModel.swift

import Foundation
import SwiftUI

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var todayPomodoros: Int = 0
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
        await loadTodayStats()
        await loadWeeklyStats()
        await calculateStreak()
    }
    
    private func loadTodayStats() async {
        let sessions = await dataService.fetchTodaySessions()
        
        // Un pomodoro es una sesión de trabajo + una de descanso
        let workSessions = sessions.filter { $0.timerType == .work && $0.wasCompleted }.count
        let breakSessions = sessions.filter { ($0.timerType == .shortBreak || $0.timerType == .longBreak) && $0.wasCompleted }.count
        
        todayPomodoros = min(workSessions, breakSessions)
        
        // Calcular tiempo total de TODAS las sesiones (trabajo y descansos)
        var totalSeconds = 0
        for session in sessions {
            totalSeconds += session.duration
        }
        
        todayMinutes = totalSeconds / 60
    }
    
    private func loadWeeklyStats() async {
        let sessions = await dataService.fetchWeeklySessions()
        
        // Crear array con los últimos 7 días
        var dailyStats: [DailyStats] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            // Filtrar sesiones para ese día
            let daySessions = sessions.filter { $0.startDate >= startOfDay && $0.startDate < endOfDay && $0.wasCompleted }
            
            let workSessions = daySessions.filter { $0.timerType == .work }.count
            let breakSessions = daySessions.filter { $0.timerType == .shortBreak || $0.timerType == .longBreak }.count
            
            let pomodoros = min(workSessions, breakSessions)
            
            dailyStats.append(DailyStats(date: date, pomodoros: pomodoros))
        }
        
        weeklyData = dailyStats.reversed()
    }
    
    private func calculateStreak() async {
        // Obtener todas las sesiones ordenadas por fecha
        let allSessions = await dataService.fetchAllWorkSessions()
        
        guard !allSessions.isEmpty else {
            currentStreak = 0
            return
        }
        
        // Agrupar sesiones por día
        var sessionsByDay: [Date: Int] = [:]
        
        for session in allSessions {
            let day = calendar.startOfDay(for: session.startDate)
            sessionsByDay[day, default: 0] += 1
        }
        
        // Calcular racha actual
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // Verificar si hay sesiones hoy
        if sessionsByDay[checkDate] != nil && sessionsByDay[checkDate]! > 0 {
            streak = 1
            
            // Verificar días anteriores consecutivos
            while true {
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                
                if let sessionsCount = sessionsByDay[previousDay], sessionsCount > 0 {
                    streak += 1
                    checkDate = previousDay
                } else {
                    break
                }
            }
        } else {
            // Si no hay sesiones hoy, verificar si la racha terminó ayer
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                currentStreak = 0
                return
            }
            
            if sessionsByDay[yesterday] != nil && sessionsByDay[yesterday]! > 0 {
                // La racha terminó ayer, no se cuenta
                currentStreak = 0
                return
            }
        }
        
        currentStreak = streak
    }
}
