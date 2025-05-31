// TimerType.swift

import Foundation

enum TimerType: String, CaseIterable {
    case work = "work"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"
    
    var displayName: String {
        switch self {
        case .work:
            return String(localized: "Trabajo")
        case .shortBreak:
            return String(localized: "Descanso")
        case .longBreak:
            return String(localized: "Descanso Largo")
        }
    }
    
    var defaultDuration: Int {
        switch self {
        case .work:
            return 25 * 60 // 25 minutos
        case .shortBreak:
            return 5 * 60  // 5 minutos
        case .longBreak:
            return 15 * 60 // 15 minutos
        }
    }
    
    var soundFileName: String {
        switch self {
        case .work:
            return "work-complete"
        case .shortBreak:
            return "break-complete"
        case .longBreak:
            return "long-break-complete"
        }
    }
}
