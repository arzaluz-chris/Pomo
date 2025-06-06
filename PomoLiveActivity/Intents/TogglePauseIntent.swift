// TogglePauseIntent.swift
// Ubicación: PomoLiveActivity/Intents/TogglePauseIntent.swift

import AppIntents
import ActivityKit

struct TogglePauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Pause"
    
    @Parameter(title: "Session Type")
    var sessionType: String
    
    @Parameter(title: "Is Paused")
    var isPaused: Bool
    
    init() {}
    
    init(sessionType: String, isPaused: Bool) {
        self.sessionType = sessionType
        self.isPaused = isPaused
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
        
        // Actualizar el estado
        let newState: PomoActivityAttributes.ContentState
        
        if isPaused {
            // Reanudar
            let remainingTime = activity.contentState.timeRemaining
            newState = PomoActivityAttributes.ContentState(
                timeRemaining: remainingTime,
                isPaused: false,
                endTime: Date().addingTimeInterval(TimeInterval(remainingTime))
            )
        } else {
            // Pausar
            let currentRemaining = Int(activity.contentState.endTime.timeIntervalSinceNow)
            newState = PomoActivityAttributes.ContentState(
                timeRemaining: max(0, currentRemaining),
                isPaused: true,
                endTime: activity.contentState.endTime
            )
        }
        
        await activity.update(using: newState)
        
        // Notificar a la app principal a través de NotificationCenter
        NotificationCenter.default.post(
            name: Notification.Name("LiveActivityTogglePause"),
            object: nil,
            userInfo: ["sessionType": sessionType, "isPaused": !isPaused]
        )
        
        return .result()
    }
}
