// PomoExpandedViews.swift

import SwiftUI
import WidgetKit
import AppIntents

struct ExpandedCenterView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 5) {
                SessionIcon(state: state, size: 14)
                Text(isStale ? String(localized: "Session complete", comment: "Live Activity: session finished")
                             : state.timerTypeDisplayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            ActivityCountdownText(state: state, isStale: isStale)
                .monospacedDigit()
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ExpandedBottomView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        HStack(spacing: 16) {
            ActivityControlButton(intent: ResetTimerIntent(), systemImage: "arrow.counterclockwise",
                                  label: String(localized: "Reset Timer"))

            if state.isRunning && !isStale {
                ActivityPrimaryButton(intent: PauseTimerIntent(), systemImage: "pause.fill",
                                      title: String(localized: "Pause"), tint: state.tint)
            } else {
                // Also starts the next session after one has finished
                ActivityPrimaryButton(intent: PlayTimerIntent(), systemImage: "play.fill",
                                      title: isStale ? String(localized: "Next", comment: "Live Activity: start next session")
                                                     : String(localized: "Resume"),
                                      tint: state.tint)
            }

            ActivityControlButton(intent: SkipTimerIntent(), systemImage: "forward.fill",
                                  label: String(localized: "Skip Session"))
        }
    }
}

struct ActivityPrimaryButton<I: AppIntent>: View {
    let intent: I
    let systemImage: String
    let title: String
    let tint: Color

    var body: some View {
        Button(intent: intent) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(minHeight: 28)
                .padding(.horizontal, 16)
                .background(tint, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ActivityControlButton<I: AppIntent>: View {
    let intent: I
    let systemImage: String
    let label: String

    var body: some View {
        Button(intent: intent) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.15), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
