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
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }
    
    func scheduleSessionComplete(type: TimerType) async {
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaults.isNotificationEnabled) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "¡Sesión completada!")
        content.sound = .default
        
        switch type {
        case .work:
            content.body = String(localized: "Has completado una sesión de trabajo. ¡Toma un descanso!")
        case .shortBreak:
            content.body = String(localized: "El descanso ha terminado. ¡Es hora de trabajar!")
        case .longBreak:
            content.body = String(localized: "El descanso largo ha terminado. ¡Vamos a por otra ronda!")
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
}
