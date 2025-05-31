// DataService.swift

import Foundation
import SwiftData

@MainActor
class DataService {
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func saveSession(startDate: Date, endDate: Date, duration: Int, type: TimerType, wasCompleted: Bool) async {
        guard let modelContext = modelContext else { return }
        
        let session = TimerSession(
            startDate: startDate,
            endDate: endDate,
            duration: duration, // Esto ya viene en segundos
            type: type,
            wasCompleted: wasCompleted
        )
        
        modelContext.insert(session)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving session: \(error)")
        }
    }
    
    func fetchTodaySessions() async -> [TimerSession] {
        guard let modelContext = modelContext else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate { session in
                session.startDate >= startOfDay && session.startDate < endOfDay
            },
            sortBy: [SortDescriptor(\.startDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }
    
    func fetchWeeklySessions() async -> [TimerSession] {
        guard let modelContext = modelContext else { return [] }
        
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }
        
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate { session in
                session.startDate >= weekStart
            },
            sortBy: [SortDescriptor(\.startDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }
}
