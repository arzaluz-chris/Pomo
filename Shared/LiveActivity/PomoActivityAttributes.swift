// PomoActivityAttributes.swift

import Foundation
import ActivityKit

struct PomoActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timerType: String
        var isRunning: Bool
        var endTime: Date?
        var timeRemaining: Int
        var totalDuration: Int

        var progress: Double {
            guard totalDuration > 0 else { return 0 }
            return 1.0 - (Double(timeRemaining) / Double(totalDuration))
        }

        var timerTypeDisplayName: String {
            switch timerType {
            case TimerType.work.rawValue:
                return String(localized: "Work", comment: "Work session type")
            case TimerType.shortBreak.rawValue:
                return String(localized: "Break", comment: "Short break session type")
            case TimerType.longBreak.rawValue:
                return String(localized: "Long Break", comment: "Long break session type")
            default:
                return timerType
            }
        }
    }
}
