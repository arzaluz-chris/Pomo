// PomoLockScreenView.swift

import SwiftUI
import WidgetKit
import AppIntents

struct PomoLockScreenView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    @Environment(\.activityFamily) private var activityFamily

    var body: some View {
        switch activityFamily {
        case .small:
            SmallActivityView(state: state, isStale: isStale)
        default:
            lockScreen
        }
    }

    private var lockScreen: some View {
        HStack(spacing: 12) {
            ZStack {
                ActivityProgressRing(state: state, isStale: isStale, lineWidth: 4)
                SessionIcon(state: state, size: 20)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                ActivityCountdownText(state: state, isStale: isStale)
                    .monospacedDigit()
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            HStack(spacing: 8) {
                ActivityControlButton(intent: ResetTimerIntent(), systemImage: "arrow.counterclockwise",
                                      label: String(localized: "Reset Timer"))

                if state.isRunning && !isStale {
                    roundButton(PauseTimerIntent(), systemImage: "pause.fill", label: String(localized: "Pause"))
                } else {
                    roundButton(PlayTimerIntent(), systemImage: "play.fill",
                                label: isStale ? String(localized: "Next", comment: "Live Activity: start next session")
                                               : String(localized: "Resume"))
                }

                ActivityControlButton(intent: SkipTimerIntent(), systemImage: "forward.fill",
                                      label: String(localized: "Skip Session"))
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

    private func roundButton<I: AppIntent>(_ intent: I, systemImage: String, label: String) -> some View {
        Button(intent: intent) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(state.tint, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Apple Watch Smart Stack layout (also used by other small presentations).
struct SmallActivityView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                ActivityProgressRing(state: state, isStale: isStale, lineWidth: 3)
                SessionIcon(state: state, size: 14)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 0) {
                ActivityCountdownText(state: state, isStale: isStale)
                    .monospacedDigit()
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text(isStale ? String(localized: "Session complete", comment: "Live Activity: session finished")
                             : state.timerTypeDisplayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .accessibilityElement(children: .combine)
    }
}
