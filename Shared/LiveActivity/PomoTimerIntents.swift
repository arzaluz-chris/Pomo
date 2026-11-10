// PomoTimerIntents.swift

import Foundation
import AppIntents

@available(iOS 16.1, *)
struct PlayTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    static var description: IntentDescription = IntentDescription("Resumes the Pomo timer")

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(.play)
        return .result()
    }
}

@available(iOS 16.1, *)
struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description: IntentDescription = IntentDescription("Pauses the Pomo timer")

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(.pause)
        return .result()
    }
}

@available(iOS 16.1, *)
struct ResetTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    static var description: IntentDescription = IntentDescription("Resets the Pomo timer")

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(.reset)
        return .result()
    }
}

@available(iOS 16.1, *)
struct SkipTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip Session"
    static var description: IntentDescription = IntentDescription("Skips the current Pomo session")

    func perform() async throws -> some IntentResult {
        await PomoTimerActionDispatcher.dispatch(.skip)
        return .result()
    }
}
