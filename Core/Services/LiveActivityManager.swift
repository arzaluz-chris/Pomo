// LiveActivityManager.swift

import Foundation
import ActivityKit

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<PomoActivityAttributes>?

    private init() {}

    func startLiveActivity(timerType: TimerType, timeRemaining: Int, totalDuration: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End any existing activity before starting a new one
        endLiveActivity()

        let attributes = PomoActivityAttributes()
        let endTime = Date().addingTimeInterval(TimeInterval(timeRemaining))

        let state = PomoActivityAttributes.ContentState(
            timerType: timerType.rawValue,
            isRunning: true,
            endTime: endTime,
            timeRemaining: timeRemaining,
            totalDuration: totalDuration
        )

        let content = ActivityContent(state: state, staleDate: endTime)

        do {
            currentActivity = try Activity<PomoActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("⚠️ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    func updateLiveActivity(timerType: TimerType, isRunning: Bool, timeRemaining: Int, totalDuration: Int) {
        guard let activity = currentActivity else { return }

        let endTime: Date? = isRunning ? Date().addingTimeInterval(TimeInterval(timeRemaining)) : nil

        let state = PomoActivityAttributes.ContentState(
            timerType: timerType.rawValue,
            isRunning: isRunning,
            endTime: endTime,
            timeRemaining: timeRemaining,
            totalDuration: totalDuration
        )

        let content = ActivityContent(state: state, staleDate: endTime)

        Task {
            await activity.update(content)
        }
    }

    func endLiveActivity() {
        guard let activity = currentActivity else { return }

        let finalState = PomoActivityAttributes.ContentState(
            timerType: TimerType.work.rawValue,
            isRunning: false,
            endTime: nil,
            timeRemaining: 0,
            totalDuration: 0
        )

        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .immediate)
        }

        currentActivity = nil
    }
}
