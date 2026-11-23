// PomoLockScreenView.swift
//
// Lock Screen / StandBy / banner: the session's color field with a cream ring and controls.
// The Apple Watch Smart Stack uses the small layout.

import SwiftUI
import WidgetKit
import AppIntents

struct PomoLockScreenView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    @Environment(\.activityFamily) private var activityFamily

    private let cream = Color(pomoHex: 0xFFF4E6)
    private let ink = Color(pomoHex: 0x2B1714)

    var body: some View {
        switch activityFamily {
        case .small:
            SmallActivityView(state: state, isStale: isStale)
        default:
            lockScreen
        }
    }

    private var lockScreen: some View {
        HStack(spacing: 14) {
            ZStack {
                ActivityProgressRing(state: state, isStale: isStale, color: cream,
                                     track: cream.opacity(0.25), lineWidth: 5)
                SessionIcon(state: state, size: 22, color: cream)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(subtitle)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(state.type.onFieldSecondary)
                ActivityCountdownText(state: state, isStale: isStale)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(cream)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                ActivityRoundButton(intent: ResetTimerIntent(), systemImage: "arrow.counterclockwise",
                                    label: String(localized: "Reset Timer"), diameter: 38,
                                    foreground: cream, background: ink.opacity(0.22))
                if state.isRunning && !isStale {
                    ActivityRoundButton(intent: PauseTimerIntent(), systemImage: "pause.fill",
                                        label: String(localized: "Pause"), diameter: 48,
                                        foreground: cream, background: ink)
                } else {
                    ActivityRoundButton(intent: PlayTimerIntent(), systemImage: "play.fill",
                                        label: isStale ? String(localized: "Next", comment: "Live Activity: start next session")
                                                       : String(localized: "Resume"),
                                        diameter: 48, foreground: cream, background: ink)
                }
                ActivityRoundButton(intent: SkipTimerIntent(), systemImage: "forward.end.fill",
                                    label: String(localized: "Skip Session"), diameter: 38,
                                    foreground: cream, background: ink.opacity(0.22))
            }
        }
        .padding(16)
    }

    private var subtitle: String {
        if isStale {
            return String(localized: "Session complete", comment: "Live Activity: session finished")
        }
        if !state.isRunning {
            return String(localized: "Paused", comment: "Timer state label") + " · " + state.timerTypeDisplayName
        }
        return state.timerTypeDisplayName
    }
}

/// Apple Watch Smart Stack layout.
struct SmallActivityView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    private let cream = Color(pomoHex: 0xFFF4E6)

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                ActivityProgressRing(state: state, isStale: isStale, color: cream,
                                     track: cream.opacity(0.25), lineWidth: 3)
                SessionIcon(state: state, size: 14, color: cream)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 0) {
                ActivityCountdownText(state: state, isStale: isStale)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(cream)
                Text(isStale ? String(localized: "Session complete", comment: "Live Activity: session finished")
                             : state.timerTypeDisplayName)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(state.type.onFieldSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .accessibilityElement(children: .combine)
    }
}
