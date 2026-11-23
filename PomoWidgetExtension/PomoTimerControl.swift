// PomoTimerControl.swift
//
// Control Center / Lock Screen / Action button control (iOS 18): starts or pauses the timer.

import SwiftUI
import WidgetKit
import AppIntents

struct PomoTimerControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Constants.Widgets.timerControlKind, provider: Provider()) { isRunning in
            ControlWidgetToggle(isOn: isRunning, action: ToggleTimerIntent()) {
                Label("Pomo", systemImage: "timer")
            } valueLabel: { isOn in
                Label(isOn ? String(localized: "Focusing", comment: "Control Center: timer running")
                           : String(localized: "Start", comment: "Control Center: timer stopped"),
                      systemImage: isOn ? "pause.fill" : "play.fill")
            }
            .tint(Color("PomoPrimary"))
        }
        .displayName("Pomo")
        .description(LocalizedStringResource("Start or pause your focus session.", comment: "Control Center control description"))
    }

    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }

        func currentValue() async throws -> Bool {
            guard let state = TimerStateStore.appGroup().load(), state.isRunning,
                  let endDate = state.endDate else { return false }
            return endDate > Date()
        }
    }
}
