// NotificationService.swift

import UserNotifications

class NotificationService {
    
    init() {
        // Establecer valores por defecto si es la primera vez
        if UserDefaults.standard.object(forKey: Constants.UserDefaults.isNotificationEnabled) == nil {
            UserDefaults.standard.set(true, forKey: Constants.UserDefaults.isNotificationEnabled)
        }
        
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
    
    func scheduleFutureNotification(type: TimerType, timeInterval: TimeInterval) async {
        // Verificar si las notificaciones están habilitadas
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaults.isNotificationEnabled) else {
            return
        }
        
        // Verificar permisos
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            return
        }
        
        // CANCELAR TODAS las notificaciones anteriores
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "¡Tiempo completado!")
        
        // Configurar sonido
        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
            let soundName = "\(type.soundFileName).mp3"
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
        } else {
            content.sound = .default
        }
        
        // Configurar mensaje según el tipo que ACABA DE TERMINAR
        switch type {
        case .work:
            content.body = String(localized: "Has completado una sesión de trabajo. ¡Toma un descanso!")
        case .shortBreak:
            content.body = String(localized: "El descanso ha terminado. ¡Es hora de trabajar!")
        case .longBreak:
            content.body = String(localized: "El descanso largo ha terminado. ¡Vamos a por otra ronda!")
        }
        
        // Crear trigger con tiempo específico
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // Usar un identificador único para evitar conflictos
        let request = UNNotificationRequest(
            identifier: "timer-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled notification for \(type.rawValue) completion in \(Int(timeInterval)) seconds")
        } catch {
            print("❌ Error scheduling notification: \(error)")
        }
    }
}
