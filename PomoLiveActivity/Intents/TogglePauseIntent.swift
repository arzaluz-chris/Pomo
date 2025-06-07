// TogglePauseIntent.swift
// Ubicación: PomoLiveActivity/Intents/TogglePauseIntent.swift

import AppIntents
import ActivityKit
import Foundation

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
        print("TogglePauseIntent - Iniciando para sessionType: \(sessionType), isPaused: \(isPaused)")
        
        // Buscar TODAS las actividades y filtrar la correcta
        let activities = Activity<PomoActivityAttributes>.activities
        print("TogglePauseIntent - Actividades encontradas: \(activities.count)")
        
        guard let activity = activities.first(where: { $0.attributes.sessionType == sessionType }) else {
            print("TogglePauseIntent - No se encontró actividad para el tipo: \(sessionType)")
            return .result()
        }
        
        print("TogglePauseIntent - Actividad encontrada, estado actual isPaused: \(activity.content.state.isPaused)")
        
        // Determinar el nuevo estado (invertir el estado actual)
        let newIsPaused = !activity.content.state.isPaused
        let currentState = activity.content.state
        
        let newState: PomoActivityAttributes.ContentState
        
        if newIsPaused {
            // Pausar - mantener el tiempo actual
            let currentRemaining = max(0, Int(currentState.endTime.timeIntervalSinceNow))
            newState = PomoActivityAttributes.ContentState(
                timeRemaining: currentRemaining,
                isPaused: true,
                endTime: currentState.endTime,
                startTime: currentState.startTime
            )
            print("TogglePauseIntent - Pausando con tiempo restante: \(currentRemaining)")
        } else {
            // Reanudar - calcular nuevo endTime
            let remainingTime = currentState.timeRemaining
            let newEndTime = Date().addingTimeInterval(TimeInterval(remainingTime))
            let totalDuration = activity.attributes.totalDuration
            let newStartTime = newEndTime.addingTimeInterval(-TimeInterval(totalDuration))
            
            newState = PomoActivityAttributes.ContentState(
                timeRemaining: remainingTime,
                isPaused: false,
                endTime: newEndTime,
                startTime: newStartTime
            )
            print("TogglePauseIntent - Reanudando con tiempo restante: \(remainingTime)")
        }
        
        // Actualizar la Live Activity
        await activity.update(ActivityContent(state: newState, staleDate: nil))
        print("TogglePauseIntent - Live Activity actualizada")
        
        // Usar UserDefaults con App Group para comunicación
        if let userDefaults = UserDefaults(suiteName: "group.com.christian-arzaluz.pomo") {
            userDefaults.set(newIsPaused, forKey: "LiveActivity_IsPaused_\(sessionType)")
            userDefaults.set(Date().timeIntervalSince1970, forKey: "LiveActivity_LastUpdate_\(sessionType)")
            userDefaults.set(newState.timeRemaining, forKey: "LiveActivity_TimeRemaining_\(sessionType)")
            userDefaults.synchronize()
            print("TogglePauseIntent - UserDefaults actualizado en App Group")
        }
        
        // También enviar notificación
        await MainActor.run {
            NotificationCenter.default.post(
                name: Notification.Name("LiveActivityTogglePause"),
                object: nil,
                userInfo: [
                    "sessionType": sessionType,
                    "isPaused": newIsPaused,
                    "timeRemaining": newState.timeRemaining
                ]
            )
            print("TogglePauseIntent - Notificación enviada")
        }
        
        return .result()
    }
}
