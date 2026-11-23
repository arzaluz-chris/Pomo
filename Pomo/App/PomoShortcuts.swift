// PomoShortcuts.swift
//
// App Shortcuts: available in Siri, Spotlight, the Shortcuts app and the Action button
// without any setup. Spanish phrases live in AppShortcuts.xcstrings.

import AppIntents

struct PomoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start a focus session in \(.applicationName)",
                "Start focusing with \(.applicationName)",
                "Start a \(.applicationName)"
            ],
            shortTitle: "Start Focus",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: StartBreakIntent(),
            phrases: [
                "Start a break in \(.applicationName)",
                "Take a break with \(.applicationName)"
            ],
            shortTitle: "Start Break",
            systemImageName: "cup.and.saucer.fill"
        )
        AppShortcut(
            intent: PauseTimerIntent(),
            phrases: [
                "Pause \(.applicationName)",
                "Pause the \(.applicationName) timer"
            ],
            shortTitle: "Pause",
            systemImageName: "pause.fill"
        )
        AppShortcut(
            intent: PlayTimerIntent(),
            phrases: [
                "Resume \(.applicationName)",
                "Resume the \(.applicationName) timer"
            ],
            shortTitle: "Resume",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: TimeRemainingIntent(),
            phrases: [
                "How much time is left in \(.applicationName)",
                "Check my \(.applicationName) timer"
            ],
            shortTitle: "Time Remaining",
            systemImageName: "hourglass"
        )
    }
}
