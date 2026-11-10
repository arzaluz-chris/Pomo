// Core/Services/NotificationService.swift

import Foundation
import UserNotifications

/// Schedules the end-of-session alert.
///
/// The alert is scheduled as soon as a session starts or resumes (not only when the
/// app goes to the background), so it also covers sessions started from the Live
/// Activity, from Apple Watch, or while the app is already in the background.
/// All work runs on one serial queue so a quick start → pause can never leave a
/// stale alert scheduled.
@MainActor
final class NotificationService {
    private let center = UNUserNotificationCenter.current()
    private var queue: Task<Void, Never>?

    func scheduleCompletion(for type: TimerType, at endDate: Date) {
        enqueue { center in
            center.removePendingNotificationRequests(withIdentifiers: [Constants.Notifications.timerCompletionIdentifier])

            guard UserDefaults.standard.bool(forKey: Constants.UserDefaults.isNotificationEnabled) else { return }
            guard endDate.timeIntervalSinceNow > 0 else { return }

            // Ask in context (first time a session starts) instead of at launch
            if await center.notificationSettings().authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            }
            let status = await center.notificationSettings().authorizationStatus
            guard status == .authorized || status == .provisional else { return }

            // Re-check: the session may have ended while we waited for the permission prompt
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
            if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
                content.sound = .default
            }
            content.interruptionLevel = .timeSensitive

            let request = UNNotificationRequest(
                identifier: Constants.Notifications.timerCompletionIdentifier,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            )
            do {
                try await center.add(request)
            } catch {
                print("❌ Error scheduling notification: \(error)")
            }
        }
    }

    func cancelCompletion() {
        enqueue { center in
            center.removePendingNotificationRequests(withIdentifiers: [Constants.Notifications.timerCompletionIdentifier])
        }
    }

    /// Removes alerts already shown in Notification Center (pending ones stay scheduled).
    func clearDelivered() {
        enqueue { center in
            center.removeAllDeliveredNotifications()
            try? await center.setBadgeCount(0)
        }
    }

    /// Waits until every queued operation has finished. Used by App Intents, which
    /// must finish their work before the system suspends the app again.
    func waitForPendingWork() async {
        await queue?.value
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
