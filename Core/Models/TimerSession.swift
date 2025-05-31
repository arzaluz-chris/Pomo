// TimerSession.swift

import Foundation
import SwiftData

@Model
final class TimerSession {
    var startDate: Date
    var endDate: Date
    var duration: Int
    var type: String
    var wasCompleted: Bool
    
    init(startDate: Date, endDate: Date, duration: Int, type: TimerType, wasCompleted: Bool) {
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.type = type.rawValue
        self.wasCompleted = wasCompleted
    }
    
    var timerType: TimerType {
        TimerType(rawValue: type) ?? .work
    }
}
