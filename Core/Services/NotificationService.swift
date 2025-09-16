// Core/Services/NotificationService.swift

import UserNotifications

class NotificationService {
    
    init() {
        Task {
            await requestPermission()
        }
    }
    
    // --- FUNCIÓN CORREGIDA ---
    func requestPermission() async {
        do {
            // Ya no se incluye `.timeSensitive` aquí. El permiso se maneja con el entitlement.
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print("Notification permission granted: \(granted)")
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }
    
    func scheduleTimerCompletionNotification(for type: TimerType, in seconds: TimeInterval) async {
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaults.isNotificationEnabled) else {
            print("❌ Notifications disabled by user preference")
            return
        }
        
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("❌ No notification permissions")
            return
        }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "¡Tiempo completado!")
        
        switch type {
        case .work:
            content.body = String(localized: "Has completado una sesión de trabajo. ¡Toma un descanso!")
        case .shortBreak:
            content.body = String(localized: "El descanso ha terminado. ¡Es hora de trabajar!")
        case .longBreak:
            content.body = String(localized: "El descanso largo ha terminado. ¡Vamos a por otra ronda!")
        }
        
        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
            content.sound = .default
        }
        
        // Esta línea sigue siendo correcta y necesaria.
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pomodoro-timer-completion",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled time-sensitive notification for \(type.rawValue) in \(Int(seconds)) seconds")
        } catch {
            print("❌ Error scheduling notification: \(error)")
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
