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

    // App Group shared by the apps and their extensions
    struct AppGroup {
        static let identifier = "group.com.christian-arzaluz.pomo"
    }

    // Live Activity
    struct LiveActivity {
        static let appGroupIdentifier = AppGroup.identifier
        static let pendingActionKey = "pendingTimerAction"
        static let actionTimestampKey = "timerActionTimestamp"
    }

    // Watch UI
    struct WatchUI {
        static let timerCircleSize: CGFloat = 105
        static let strokeWidth: CGFloat = 7
    }

    // Watch complication state (written by the Watch app, read by the widget extension
    // through the App Group — each process has its own UserDefaults.standard)
    struct WatchComplication {
        static let timerType = "watch_complication_timerType"
        static let timeRemaining = "watch_complication_timeRemaining"
        static let isActive = "watch_complication_isActive"
        static let totalDuration = "watch_complication_totalDuration"
        static let endTime = "watch_complication_endTime"
    }

    // Widget and control kinds (the app reloads them when the timer changes)
    struct Widgets {
        static let timerControlKind = "com.christian-arzaluz.Pomo.TimerControl"
        static let todayWidgetKind = "com.christian-arzaluz.Pomo.TodayWidget"
    }

    // Local notification identifiers
    struct Notifications {
        static let timerCompletionIdentifier = "pomodoro-timer-completion"
    }

    // Watch Connectivity
    struct WatchConnectivity {
        static let settingsKey = "settingsSync"
        static let timerStateKey = "timerStateSync"
        static let completedSessionKey = "completedSessionSync"
    }
}
