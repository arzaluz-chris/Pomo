// PomoTimerIntents.swift
//
// App Intents for the Live Activity buttons, Control Center, Siri, Shortcuts, Spotlight
// and the Action button. They conform to LiveActivityIntent so the system runs them in
// the app's process, where they can change the timer and start or update the Live Activity
// even when the app isn't open.

import Foundation
import AppIntents

struct PlayTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    static var description: IntentDescription = IntentDescription("Resumes the Pomo timer")

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(.play)
        return .result()
    }
}

struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description: IntentDescription = IntentDescription("Pauses the Pomo timer")

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(.pause)
        return .result()
    }
}

struct ResetTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    static var description: IntentDescription = IntentDescription("Resets the Pomo timer")

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(.reset)
        return .result()
    }
}

struct SkipTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip Session"
    static var description: IntentDescription = IntentDescription("Skips the current Pomo session")

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(.skip)
        return .result()
    }
}

struct StartFocusIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description: IntentDescription = IntentDescription("Starts a new Pomo focus session")

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(.startFocus)
        return .result()
    }
}

struct StartBreakIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Start Break"
    static var description: IntentDescription = IntentDescription("Starts a Pomo break")

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(.startBreak)
        return .result()
    }
}

/// Used by the Control Center toggle: on starts or resumes, off pauses.
struct ToggleTimerIntent: SetValueIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Start or Pause Timer"
    static var description: IntentDescription = IntentDescription("Starts, resumes or pauses the Pomo timer")

    @Parameter(title: "Running")
    var value: Bool

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(value ? .play : .pause)
        return .result()
    }
}

/// Answers "how much time is left?" from the shared state (no app launch needed).
struct TimeRemainingIntent: AppIntent {
    static var title: LocalizedStringResource = "Time Remaining"
    static var description: IntentDescription = IntentDescription("Tells how much time is left in the current Pomo session")

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Int> {
        let now = Date()
        guard let state = TimerStateStore.appGroup().load(), !state.isIdle else {
            return .result(value: 0, dialog: IntentDialog(LocalizedStringResource("No session is running.")))
        }
        // Settings aren't needed: running and paused states carry their own remaining time
        let seconds = state.remaining(at: now, settings: .default)
        let remaining = Duration.seconds(seconds).formatted(.units(allowed: [.minutes, .seconds], width: .wide))
        let type = state.type.displayName
        if state.isPaused {
            return .result(value: seconds, dialog: IntentDialog(LocalizedStringResource("\(type) is paused with \(remaining) left.")))
        }
        return .result(value: seconds, dialog: IntentDialog(LocalizedStringResource("\(remaining) left in \(type).")))
    }
}
