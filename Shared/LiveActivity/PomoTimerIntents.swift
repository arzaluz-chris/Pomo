// PomoTimerIntents.swift

import Foundation
import AppIntents

@available(iOS 16.1, *)
struct PlayTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    static var description: IntentDescription = IntentDescription("Resumes the Pomo timer")

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: Constants.LiveActivity.appGroupIdentifier)
        defaults?.set(PomoTimerAction.play.rawValue, forKey: Constants.LiveActivity.pendingActionKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: Constants.LiveActivity.actionTimestampKey)
        return .result()
    }
}

@available(iOS 16.1, *)
struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description: IntentDescription = IntentDescription("Pauses the Pomo timer")

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: Constants.LiveActivity.appGroupIdentifier)
        defaults?.set(PomoTimerAction.pause.rawValue, forKey: Constants.LiveActivity.pendingActionKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: Constants.LiveActivity.actionTimestampKey)
        return .result()
    }
}

@available(iOS 16.1, *)
struct ResetTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reset Timer"
    static var description: IntentDescription = IntentDescription("Resets the Pomo timer")

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: Constants.LiveActivity.appGroupIdentifier)
        defaults?.set(PomoTimerAction.reset.rawValue, forKey: Constants.LiveActivity.pendingActionKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: Constants.LiveActivity.actionTimestampKey)
        return .result()
    }
}

@available(iOS 16.1, *)
struct SkipTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip Session"
    static var description: IntentDescription = IntentDescription("Skips the current Pomo session")

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: Constants.LiveActivity.appGroupIdentifier)
        defaults?.set(PomoTimerAction.skip.rawValue, forKey: Constants.LiveActivity.pendingActionKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: Constants.LiveActivity.actionTimestampKey)
        return .result()
    }
}
