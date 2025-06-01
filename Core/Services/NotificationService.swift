// NotificationService.swift

import UserNotifications

class NotificationService {
    
    init() {
        Task {
            await requestPermission()
        }
    }
    
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print("Notification permission granted: \(granted)")
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }
    
    // ÚNICO método para programar notificaciones
    func scheduleTimerCompletionNotification(for type: TimerType, in seconds: TimeInterval) async {
        // Verificar si las notificaciones están habilitadas
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaults.isNotificationEnabled) else {
            print("❌ Notifications disabled by user preference")
            return
        }
        
        // Verificar permisos del sistema
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print("❌ No notification permissions")
            return
        }
        
        // IMPORTANTE: Cancelar TODAS las notificaciones pendientes para evitar duplicados
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "¡Tiempo completado!")
        
        // El mensaje depende del tipo de sesión que ACABA de terminar
        switch type {
        case .work:
            content.body = String(localized: "Has completado una sesión de trabajo. ¡Toma un descanso!")
        case .shortBreak:
            content.body = String(localized: "El descanso ha terminado. ¡Es hora de trabajar!" )
        case .longBreak:
            content.body = String(localized: "El descanso largo ha terminado. ¡Vamos a por otra ronda!" )
        }
        
        // Configurar sonido si está habilitado
        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
            content.sound = .default
        }
        
        // Programar la notificación
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pomodoro-timer-completion",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled notification for \(type.rawValue) in \(Int(seconds)) seconds")
        } catch {
            print("❌ Error scheduling notification: \(error)")
        }
    }
    
    // Cancelar todas las notificaciones
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
