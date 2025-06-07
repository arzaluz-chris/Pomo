// PomoActivityAttributes.swift
// Ubicación: Core/Models/PomoActivityAttributes.swift

import Foundation
import ActivityKit

struct PomoActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Estado dinámico (puede cambiar durante la actividad)
        var timeRemaining: Int
        var isPaused: Bool
        var endTime: Date
        var startTime: Date // Añadido para calcular progreso
    }
    
    // Estado estático (no cambia durante la actividad)
    var sessionType: String
    var totalDuration: Int
    var sessionNumber: Int
    
    // Helper para obtener el TimerType
    var timerType: TimerType? {
        return TimerType(rawValue: sessionType)
    }
}
