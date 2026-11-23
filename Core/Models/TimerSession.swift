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
    // Shared iPhone/Watch session identity, used to avoid saving the same session twice.
    // Optional so existing stores migrate automatically.
    var sessionID: String?
    
    init(startDate: Date, endDate: Date, duration: Int, type: TimerType, wasCompleted: Bool, sessionID: String? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.type = type.rawValue
        self.wasCompleted = wasCompleted
        self.sessionID = sessionID
    }
    
    var timerType: TimerType {
        TimerType(rawValue: type) ?? .work
    }
}
