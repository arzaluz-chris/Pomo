// Core/Services/NotificationService.swift

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
        content.title = NSLocalizedString("Time completed!", comment: "Title for the notification when a timer session ends")
        
        switch type {
        case .work:
            content.body = NSLocalizedString("You've completed a work session. Take a break!", comment: "Notification body when a work session is completed")
        case .shortBreak:
            content.body = NSLocalizedString("Break is over. Time to work!", comment: "Notification body when a short break is over")
        case .longBreak:
            content.body = NSLocalizedString("Long break is over. Let's go for another round!", comment: "Notification body when a long break is over")
        }
        
        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
            content.sound = .default
        }
        
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
