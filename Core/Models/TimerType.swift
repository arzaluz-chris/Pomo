// TimerType.swift

import Foundation

enum TimerType: String, CaseIterable {
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
