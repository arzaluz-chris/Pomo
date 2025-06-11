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
            // Solicitar permisos básicos (NO incluir .timeSensitive que está deprecated)
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            print("✅ Notification permission granted: \(granted)")
            
            if granted {
                // Verificar configuración de notificaciones
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                print("🔔 Authorization status: \(settings.authorizationStatus.rawValue)")
                if #available(iOS 15.0, *) {
                    print("🔔 Time Sensitive setting: \(settings.timeSensitiveSetting.rawValue)")
                }
            }
        } catch {
            print("❌ Error requesting notification permission: \(error)")
        }
    }
    
    // Método actualizado para programar notificaciones time-sensitive
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
        content.title = String(localized: "Time's up!")
        
        // Configurar el mensaje según el tipo de sesión
        switch type {
        case .work:
            content.subtitle = String(localized: "🍅 Work session completed")
            content.body = String(localized: "You've completed a work session. Take a break!")
        case .shortBreak:
            content.subtitle = String(localized: "☕ Break finished")
            content.body = String(localized: "The break is over. Time to work!")
        case .longBreak:
            content.subtitle = String(localized: "🌟 Long break completed")
            content.body = String(localized: "Your long break is over. Let's start another round!")
        }
        
        // IMPORTANTE: Marcar la notificación como Time Sensitive
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            print("✅ Setting interruption level to timeSensitive")
        }
        
        // Agregar relevance score para mayor prioridad
        if #available(iOS 15.0, *) {
            content.relevanceScore = 1.0
        }
        
        // Configurar sonido
        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
            // Usar un sonido más prominente para time-sensitive
            content.sound = .defaultCritical
        }
        
        // Badge
        content.badge = 1
        
        // Agregar categoría para acciones rápidas
        content.categoryIdentifier = "TIMER_COMPLETE"
        
        // Programar la notificación
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
    
    // Configurar categorías de notificación con acciones
    func setupNotificationCategories() {
        let startWorkAction = UNNotificationAction(
            identifier: "START_WORK",
            title: "Iniciar Trabajo",
            options: [.foreground]
        )
        
        let startBreakAction = UNNotificationAction(
            identifier: "START_BREAK",
            title: "Iniciar Descanso",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Descartar",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: "TIMER_COMPLETE",
            actions: [startWorkAction, startBreakAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // Cancelar todas las notificaciones
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
