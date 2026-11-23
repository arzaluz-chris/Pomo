// Shared/Engine/TimerType.swift

import Foundation

enum TimerType: String, CaseIterable, Codable, Sendable {
    case work = "work"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"
    
    var displayName: String {
        switch self {
        case .work:
            return NSLocalizedString("Work", comment: "Work session type")
        case .shortBreak:
            return NSLocalizedString("Break", comment: "Short break session type")
        case .longBreak:
            return NSLocalizedString("Long Break", comment: "Long break session type")
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
    
    /// Minutes the user can choose for this session type (Settings and the timer's drag).
    var adjustableMinutes: ClosedRange<Int> {
        switch self {
        case .work: return 10...60
        case .shortBreak: return 3...15
        case .longBreak: return 10...30
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
