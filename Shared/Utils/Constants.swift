// Constants.swift

import Foundation
import SwiftUI

struct Constants {
    // UserDefaults Keys
    struct UserDefaults {
        static let workDuration = "workDuration"
        static let shortBreakDuration = "shortBreakDuration"
        static let longBreakDuration = "longBreakDuration"
        static let sessionsUntilLongBreak = "sessionsUntilLongBreak"
        static let isNotificationEnabled = "isNotificationEnabled"
        static let isSoundEnabled = "isSoundEnabled"
    }
    
    // Default Values
    struct Defaults {
        static let workDuration = 25 * 60
        static let shortBreakDuration = 5 * 60
        static let longBreakDuration = 15 * 60
        static let sessionsUntilLongBreak = 4
    }
    
    // UI
    struct UI {
        static let timerCircleSize: CGFloat = 250
        static let timerStrokeWidth: CGFloat = 12
        static let buttonHeight: CGFloat = 56
        static let cornerRadius: CGFloat = 28
    }
}
