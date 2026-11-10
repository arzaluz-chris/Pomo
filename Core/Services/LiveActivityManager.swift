// LiveActivityManager.swift

import Foundation
import ActivityKit

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<PomoActivityAttributes>?
    private var queue: Task<Void, Never>?

    private init() {
        // Re-attach to an activity that outlived a previous app process (for example when
        // the system relaunches the app in the background to run a Live Activity intent).
        currentActivity = Activity<PomoActivityAttributes>.activities.first { Self.isVisible($0) }
    }

    /// The user or the system can end an activity at any time (swiping it away on the
    /// Lock Screen, the system time limit), so only reuse one that is still shown.
    private static func isVisible(_ activity: Activity<PomoActivityAttributes>) -> Bool {
        activity.activityState == .active || activity.activityState == .stale
    }

    func startLiveActivity(timerType: TimerType, timeRemaining: Int, totalDuration: Int) {
        // Reuse the running activity (resume, skip, start from a paused state). Ending and
        // re-requesting would flicker and fails while the app is in the background.
        if let activity = currentActivity, Self.isVisible(activity) {
            updateLiveActivity(timerType: timerType, isRunning: true, timeRemaining: timeRemaining, totalDuration: totalDuration)
            return
        }

        currentActivity = nil
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let endTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
        let state = PomoActivityAttributes.ContentState(
            timerType: timerType.rawValue,
            isRunning: true,
            endTime: endTime,
            timeRemaining: timeRemaining,
            totalDuration: totalDuration
        )

        do {
            currentActivity = try Activity<PomoActivityAttributes>.request(
                attributes: PomoActivityAttributes(),
                content: ActivityContent(state: state, staleDate: endTime),
                pushType: nil
            )
        } catch {
            print("⚠️ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    func updateLiveActivity(timerType: TimerType, isRunning: Bool, timeRemaining: Int, totalDuration: Int) {
        guard let activity = currentActivity, Self.isVisible(activity) else { return }

        let endTime: Date? = isRunning ? Date().addingTimeInterval(TimeInterval(timeRemaining)) : nil
        let state = PomoActivityAttributes.ContentState(
            timerType: timerType.rawValue,
            isRunning: isRunning,
            endTime: endTime,
            timeRemaining: timeRemaining,
            totalDuration: totalDuration
        )
        let content = ActivityContent(state: state, staleDate: endTime)

        enqueue {
            await activity.update(content)
        }
    }

    func endLiveActivity() {
        currentActivity = nil

        let finalState = PomoActivityAttributes.ContentState(
            timerType: TimerType.work.rawValue,
            isRunning: false,
            endTime: nil,
            timeRemaining: 0,
            totalDuration: 0
        )
        let content = ActivityContent(state: finalState, staleDate: nil)

        // End every Pomo activity, including any orphaned by an earlier process. Take the
        // list now, so an activity started after this call isn't ended when the queue runs.
        let activitiesToEnd = Activity<PomoActivityAttributes>.activities
        enqueue {
            for activity in activitiesToEnd {
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
    }

    /// Waits until queued updates are delivered. App Intents await this so the change is
    /// applied before the system suspends the app again.
    func waitForPendingUpdates() async {
        await queue?.value
    }

    private func enqueue(_ work: @escaping @MainActor () async -> Void) {
        let previous = queue
        queue = Task { @MainActor in
            await previous?.value
            await work()
        }
    }
}
