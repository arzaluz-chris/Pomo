// Pomo/Services/PomoAlarmService.swift
//
// Optional "alarm-style" end-of-session alert (iOS 26+). Uses AlarmKit, which sounds even
// in silent mode or during a Focus and is forwarded to a paired Apple Watch. Off by
// default: the regular Time Sensitive notification is less intrusive.

import Foundation
import SwiftUI
#if canImport(AlarmKit)
import AlarmKit
#endif

enum PomoAlarmPreference {
    static let key = "useAlarmAlerts"

    /// True when the user turned alarm-style alerts on and the system supports them.
    static var isActive: Bool {
        guard #available(iOS 26, *) else { return false }
        return UserDefaults.standard.bool(forKey: key)
    }
}

#if canImport(AlarmKit)
@available(iOS 26, *)
struct PomoAlarmMetadata: AlarmMetadata {}

@available(iOS 26, *)
@MainActor
final class PomoAlarmService {
    static let shared = PomoAlarmService()

    private let manager = AlarmManager.shared
    private let alarmIDKey = "scheduledAlarmID"
    private var queue: Task<Void, Never>?

    private init() {}

    var isAuthorized: Bool { manager.authorizationState == .authorized }

    /// Asks for permission (shows the system prompt the first time).
    func requestAuthorization() async -> Bool {
        do {
            return try await manager.requestAuthorization() == .authorized
        } catch {
            print("⚠️ AlarmKit authorization failed: \(error)")
            return false
        }
    }

    func scheduleCompletion(for type: TimerType, at endDate: Date) {
        enqueue { [self] in
            cancelScheduled()
            guard endDate > Date(), isAuthorized else { return }

            let alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: Self.title(for: type)),
                stopButton: AlarmButton(text: LocalizedStringResource("OK"), textColor: .white, systemImageName: "checkmark")
            )
            let attributes = AlarmAttributes<PomoAlarmMetadata>(
                presentation: AlarmPresentation(alert: alert),
                metadata: PomoAlarmMetadata(),
                tintColor: type.tint
            )
            let id = UUID()
            do {
                let configuration = AlarmManager.AlarmConfiguration<PomoAlarmMetadata>(
                    schedule: .fixed(endDate),
                    attributes: attributes
                )
                _ = try await manager.schedule(id: id, configuration: configuration)
                UserDefaults.standard.set(id.uuidString, forKey: alarmIDKey)
            } catch {
                print("⚠️ Failed to schedule alarm: \(error)")
            }
        }
    }

    func cancelCompletion() {
        enqueue { [self] in cancelScheduled() }
    }

    func waitForPendingWork() async {
        await queue?.value
    }

    private func cancelScheduled() {
        guard let string = UserDefaults.standard.string(forKey: alarmIDKey), let id = UUID(uuidString: string) else { return }
        try? manager.cancel(id: id)
        UserDefaults.standard.removeObject(forKey: alarmIDKey)
    }

    private func enqueue(_ work: @escaping @MainActor () async -> Void) {
        let previous = queue
        queue = Task { @MainActor in
            await previous?.value
            await work()
        }
    }

    private static func title(for type: TimerType) -> String {
        switch type {
        case .work:
            return NSLocalizedString("You've completed a work session. Take a break!", comment: "Notification body when a work session is completed")
        case .shortBreak:
            return NSLocalizedString("Break is over. Time to work!", comment: "Notification body when a short break is over")
        case .longBreak:
            return NSLocalizedString("Long break is over. Let's go for another round!", comment: "Notification body when a long break is over")
        }
    }
}
#endif
