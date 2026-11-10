// LiveActivityManager.swift

import Foundation
import ActivityKit

/// Mirrors the Pomodoro state in the Lock Screen / Dynamic Island Live Activity.
@MainActor
final class LiveActivityManager {
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

    /// Shows `state`. A running session starts an activity if none is visible (this only
    /// succeeds in the foreground or from a Live Activity intent); paused and idle states
    /// only update an existing one, so its buttons can resume or start the next session.
    func show(_ state: PomodoroState, settings: PomodoroSettings, now: Date = Date()) {
        let contentState = PomoActivityAttributes.ContentState(
            timerType: state.type.rawValue,
            isRunning: state.isRunning,
            endTime: state.isRunning ? state.endDate : nil,
            timeRemaining: state.remaining(at: now, settings: settings),
            totalDuration: state.plannedDuration(settings: settings)
        )
        let content = ActivityContent(state: contentState, staleDate: contentState.endTime)

        if let activity = currentActivity, Self.isVisible(activity) {
            enqueue { await activity.update(content) }
            return
        }

        currentActivity = nil
        guard state.isRunning, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            currentActivity = try Activity<PomoActivityAttributes>.request(
                attributes: PomoActivityAttributes(),
                content: content,
                pushType: nil
            )
        } catch {
            print("⚠️ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    func end() {
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
        guard !activitiesToEnd.isEmpty else { return }
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
