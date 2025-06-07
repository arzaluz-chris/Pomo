// ResetTimerIntent.swift
// Ubicación: PomoLiveActivity/Intents/ResetTimerIntent.swift

import AppIntents
import ActivityKit
import Foundation

struct ResetTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    
    @Parameter(title: "Session Type")
    var sessionType: String
    
    init() {}
    
    init(sessionType: String) {
        self.sessionType = sessionType
    }
    
    func perform() async throws -> some IntentResult {
        print("ResetTimerIntent - Iniciando para sessionType: \(sessionType)")
        
        // Buscar la actividad actual
        let activities = Activity<PomoActivityAttributes>.activities
        print("ResetTimerIntent - Actividades encontradas: \(activities.count)")
        
        guard let activity = activities.first(where: { $0.attributes.sessionType == sessionType }) else {
            print("ResetTimerIntent - No se encontró actividad para el tipo: \(sessionType)")
            return .result()
        }
        
        // Actualizar al estado inicial
        let totalDuration = activity.attributes.totalDuration
        let newEndTime = Date().addingTimeInterval(TimeInterval(totalDuration))
        let newState = PomoActivityAttributes.ContentState(
            timeRemaining: totalDuration,
            isPaused: true,
            endTime: newEndTime,
            startTime: Date()
        )
        
        print("ResetTimerIntent - Reiniciando con duración total: \(totalDuration)")
        
        // Actualizar la Live Activity
        await activity.update(ActivityContent(state: newState, staleDate: nil))
        print("ResetTimerIntent - Live Activity actualizada")
        
        // Usar UserDefaults con App Group para comunicación
        if let userDefaults = UserDefaults(suiteName: "group.com.christian-arzaluz.pomo") {
            userDefaults.set(true, forKey: "LiveActivity_IsPaused_\(sessionType)")
            userDefaults.set(Date().timeIntervalSince1970, forKey: "LiveActivity_LastUpdate_\(sessionType)")
            userDefaults.set(totalDuration, forKey: "LiveActivity_TimeRemaining_\(sessionType)")
            userDefaults.set(true, forKey: "LiveActivity_Reset_\(sessionType)")
            userDefaults.synchronize()
            print("ResetTimerIntent - UserDefaults actualizado en App Group")
        }
        
        // También enviar notificación
        await MainActor.run {
            NotificationCenter.default.post(
                name: Notification.Name("LiveActivityReset"),
                object: nil,
                userInfo: [
                    "sessionType": sessionType,
                    "timeRemaining": totalDuration
                ]
            )
            print("ResetTimerIntent - Notificación enviada")
        }
        
        return .result()
    }
}
