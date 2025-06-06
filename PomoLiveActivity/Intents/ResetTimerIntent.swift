// ResetTimerIntent.swift
// Ubicación: PomoLiveActivity/Intents/ResetTimerIntent.swift

import AppIntents
import ActivityKit

struct ResetTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    
    @Parameter(title: "Session Type")
    var sessionType: String
    
    init() {}
    
    init(sessionType: String) {
        self.sessionType = sessionType
    }
    
    func perform() async throws -> some IntentResult {
        // Buscar la actividad actual
        var foundActivity: Activity<PomoActivityAttributes>?
        for activity in Activity<PomoActivityAttributes>.activities {
            if activity.attributes.sessionType == sessionType {
                foundActivity = activity
                break
            }
        }
        
        guard let activity = foundActivity else {
            print("No se encontró actividad para el tipo: \(sessionType)")
            return .result()
        }
        
        // Actualizar al estado inicial
        let totalDuration = activity.attributes.totalDuration
        let newState = PomoActivityAttributes.ContentState(
            timeRemaining: totalDuration,
            isPaused: true,
            endTime: Date().addingTimeInterval(TimeInterval(totalDuration))
        )
        
        await activity.update(using: newState)
        
        // Notificar a la app principal
        NotificationCenter.default.post(
            name: Notification.Name("LiveActivityReset"),
            object: nil,
            userInfo: ["sessionType": sessionType]
        )
        
        return .result()
    }
}
