// PomoActivityAttributes.swift
// Ubicación: Shared/Models/PomoActivityAttributes.swift

import Foundation
import ActivityKit

struct PomoActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Estado dinámico (puede cambiar durante la actividad)
        var timeRemaining: Int
        var isPaused: Bool
        var endTime: Date // Para mostrar tiempo relativo
    }
    
    // Estado estático (no cambia durante la actividad)
    var sessionType: String // Cambiado de TimerType a String para ser Codable
    var totalDuration: Int
    var sessionNumber: Int // Número de sesión actual
    
    // Helper para obtener el TimerType
    var timerType: TimerType? {
        return TimerType(rawValue: sessionType)
    }
}
