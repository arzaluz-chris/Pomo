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
            print(NSLocalizedString("✅ Notification permission granted: \(granted)", comment: "Notification permission granted"))
            
            if granted {
                // Verificar configuración de notificaciones
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                print(NSLocalizedString("🔔 Authorization status: \(settings.authorizationStatus.rawValue)", comment: "Authorization status"))
                if #available(iOS 15.0, *) {
                    print(NSLocalizedString("🔔 Time Sensitive setting: \(settings.timeSensitiveSetting.rawValue)", comment: "Time Sensitive setting"))
                }
            }
        } catch {
            print(NSLocalizedString("❌ Error requesting notification permission: \(error)", comment: "Error requesting permission"))
        }
    }
    
    // Método actualizado para programar notificaciones time-sensitive
    func scheduleTimerCompletionNotification(for type: TimerType, in seconds: TimeInterval) async {
        // Verificar si las notificaciones están habilitadas
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaults.isNotificationEnabled) else {
            print(NSLocalizedString("❌ Notifications disabled by user preference", comment: "Notifications disabled by user preference"))
            return
        }
        
        // Verificar permisos del sistema
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            print(NSLocalizedString("❌ No notification permissions", comment: "No notification permissions"))
            return
        }
        
        // IMPORTANTE: Cancelar TODAS las notificaciones pendientes para evitar duplicados
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Time's up!", comment: "Timer completed title")
        
        // Configurar el mensaje según el tipo de sesión
        switch type {
        case .work:
            content.body = NSLocalizedString("You've completed a work session. Take a break!", comment: "Work session completed message")
            content.subtitle = NSLocalizedString("🍅 Work session completed", comment: "Work session subtitle")
        case .shortBreak:
            content.body = NSLocalizedString("Break is over. Time to work!", comment: "Short break ended message")
            content.subtitle = NSLocalizedString("☕ Break finished", comment: "Short break subtitle")
        case .longBreak:
            content.body = NSLocalizedString("Long break is over. Let's start another round!", comment: "Long break ended message")
            content.subtitle = NSLocalizedString("🌟 Long break completed", comment: "Long break subtitle")
        }
        
        // IMPORTANTE: Marcar la notificación como Time Sensitive
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            print(NSLocalizedString("✅ Setting interruption level to timeSensitive", comment: "Interruption level set"))
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
            print(NSLocalizedString("✅ Scheduled time-sensitive notification for \(type.rawValue) in \(Int(seconds)) seconds", comment: "Notification scheduled confirmation"))
        } catch {
            print(NSLocalizedString("❌ Error scheduling notification: \(error)", comment: "Error scheduling notification"))
        }
    }
    
    // Configurar categorías de notificación con acciones
    func setupNotificationCategories() {
        let startWorkAction = UNNotificationAction(
            identifier: "START_WORK",
            title: NSLocalizedString("Start Work", comment: "Start work action"),
            options: [.foreground]
        )
        
        let startBreakAction = UNNotificationAction(
            identifier: "START_BREAK",
            title: NSLocalizedString("Start Break", comment: "Start break action"),
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: NSLocalizedString("Dismiss", comment: "Dismiss action"),
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
