// DataService.swift

import Foundation
import SwiftData
import WidgetKit

@MainActor
class DataService {
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func saveSession(startDate: Date, endDate: Date, duration: Int, type: TimerType, wasCompleted: Bool, sessionID: String? = nil) async {
        guard let modelContext = modelContext else { return }

        // iPhone and Watch can both finish the same session; keep only the first record
        if let sessionID {
            var descriptor = FetchDescriptor<TimerSession>(
                predicate: #Predicate { $0.sessionID == sessionID }
            )
            descriptor.fetchLimit = 1
            if let count = try? modelContext.fetchCount(descriptor), count > 0 {
                return
            }
        }
        
        let session = TimerSession(
            startDate: startDate,
            endDate: endDate,
            duration: duration, // En segundos
            type: type,
            wasCompleted: wasCompleted,
            sessionID: sessionID
        )
        
        modelContext.insert(session)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving session: \(error)")
        }
        publishSnapshot()
    }

    /// All recorded sessions as plain values for statistics.
    func fetchSamples(since startDate: Date? = nil) -> [SessionSample] {
        guard let modelContext = modelContext else { return [] }
        var descriptor = FetchDescriptor<TimerSession>(sortBy: [SortDescriptor(\.startDate)])
        if let startDate {
            descriptor.predicate = #Predicate { $0.startDate >= startDate }
        }
        let sessions = (try? modelContext.fetch(descriptor)) ?? []
        return sessions.map {
            SessionSample(start: $0.startDate, duration: $0.duration, type: $0.timerType, wasCompleted: $0.wasCompleted)
        }
    }

    /// Writes today's totals and the streak to the App Group for the widgets.
    func publishSnapshot(now: Date = Date()) {
        guard modelContext != nil else { return }
        let snapshot = StatsCalculator.snapshot(on: now, sessions: fetchSamples())
        let defaults = UserDefaults(suiteName: Constants.AppGroup.identifier)
        guard StatsSnapshot.load(from: defaults) != snapshot else { return }
        snapshot.save(to: defaults)
        WidgetCenter.shared.reloadAllTimelines()
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
    
    // Nuevo método para obtener todas las sesiones de trabajo completadas
    func fetchAllWorkSessions() async -> [TimerSession] {
        guard let modelContext = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate { session in
                session.type == "work" && session.wasCompleted == true
            },
            sortBy: [SortDescriptor(\.startDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching all work sessions: \(error)")
            return []
        }
    }
    
    // Método adicional para debugging
    func fetchSessionsForDateRange(from startDate: Date, to endDate: Date) async -> [TimerSession] {
        guard let modelContext = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate { session in
                session.startDate >= startDate && session.startDate <= endDate
            },
            sortBy: [SortDescriptor(\.startDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching sessions for date range: \(error)")
            return []
        }
    }
}
