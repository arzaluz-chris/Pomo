// PomoTimerAction.swift

import Foundation

enum PomoTimerAction: String, Codable {
    case play
    case pause
    case reset
    case skip
    /// Starts a new focus session, discarding the current one.
    case startFocus
    /// Starts a break (the long break if one is due), discarding the current session.
    case startBreak
}

/// Routes intent actions (Live Activity buttons, Control Center, Siri, Shortcuts) to the timer.
///
/// The intents conform to `LiveActivityIntent`, which the system runs in the app's process,
/// launching it in the background if needed. The app registers `handler` at launch so
/// `perform()` changes the timer, the Live Activity and the scheduled alert right away.
/// This file is also compiled into the widget extension, where no handler exists; there
/// the action is stored in the App Group and the app applies it the next time it runs.
@MainActor
enum PomoTimerActionDispatcher {
    static var handler: ((PomoTimerAction) async -> Void)?

    static func dispatch(_ action: PomoTimerAction) async {
        if let handler {
            await handler(action)
        } else {
            let defaults = UserDefaults(suiteName: Constants.AppGroup.identifier)
            defaults?.set(action.rawValue, forKey: Constants.LiveActivity.pendingActionKey)
            defaults?.set(Date().timeIntervalSince1970, forKey: Constants.LiveActivity.actionTimestampKey)
        }
    }
}
