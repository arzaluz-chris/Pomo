// PomoWatch/Services/WatchNotificationService.swift

import Foundation
import UserNotifications

/// Schedules the end-of-session alert on Apple Watch.
///
/// watchOS suspends the app when the wrist goes down, and there is no extended
/// runtime session type that fits a Pomodoro timer, so a local notification
/// scheduled for the session's end date is the reliable way to alert the user.
/// Work is serialized so a quick start → pause can never leave a stale alert behind.
@MainActor
final class WatchNotificationService {
    private let center = UNUserNotificationCenter.current()
    private var queue: Task<Void, Never>?

    func requestAuthorizationIfNeeded() {
        enqueue { center in
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .notDetermined else { return }
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }

    func scheduleCompletion(for type: TimerType, at endDate: Date) {
        enqueue { center in
            center.removePendingNotificationRequests(withIdentifiers: [Constants.Notifications.timerCompletionIdentifier])

            guard endDate.timeIntervalSinceNow > 0 else { return }

            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
            }
            let current = await center.notificationSettings()
            guard current.authorizationStatus == .authorized || current.authorizationStatus == .provisional else { return }

            // Re-check after the awaits: the permission prompt may have taken a while
            let interval = endDate.timeIntervalSinceNow
            guard interval > 0 else { return }

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
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: Constants.Notifications.timerCompletionIdentifier,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            )
            try? await center.add(request)
        }
    }

    func cancelCompletion() {
        enqueue { center in
            center.removePendingNotificationRequests(withIdentifiers: [Constants.Notifications.timerCompletionIdentifier])
        }
    }

    func clearDelivered() {
        center.removeAllDeliveredNotifications()
    }

    private func enqueue(_ work: @escaping @MainActor (UNUserNotificationCenter) async -> Void) {
        let previous = queue
        let center = self.center
        queue = Task { @MainActor in
            await previous?.value
            await work(center)
        }
    }
}
