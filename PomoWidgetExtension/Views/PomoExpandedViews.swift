// PomoExpandedViews.swift
//
// Expanded Dynamic Island: session and time on top, the round controls below.

import SwiftUI
import WidgetKit
import AppIntents

struct ExpandedLeadingView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        // The leading region is narrow: only the icon here, the session name goes in the center
        SessionIcon(state: state, size: 18)
            .padding(.leading, 4)
    }
}

struct ExpandedTrailingView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        Group {
            if !state.isRunning && !isStale {
                Label(String(localized: "Paused", comment: "Timer state label"), systemImage: "pause.fill")
                    .labelStyle(.titleAndIcon)
            } else if let endTime = state.endTime, !isStale {
                Text(endTime, style: .time)
            }
        }
        .font(.system(size: 13, weight: .bold, design: .rounded))
        .foregroundStyle(.white.opacity(0.7))
        .lineLimit(1)
        // The trailing region proposes a very narrow width: without this "6:25 p.m." wrapped to 3 lines
        .fixedSize()
        .padding(.trailing, 4)
    }
}

struct ExpandedCenterView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        // Kept short: the expanded island is at most ~160 pt tall, controls included
        VStack(spacing: 0) {
            Text(isStale ? String(localized: "Session complete", comment: "Live Activity: session finished")
                         : state.timerTypeDisplayName)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(state.islandTint)
                .lineLimit(1)
            ActivityCountdownText(state: state, isStale: isStale)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color(pomoHex: 0xFFF4E6))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct ExpandedBottomView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    private let cream = Color(pomoHex: 0xFFF4E6)
    private let ink = Color(pomoHex: 0x2B1714)

    var body: some View {
        // Controls only: the expanded island is capped at ~160 pt and a progress rule here pushed the
        // buttons out of it (verified on iPhone 17 Pro Max). The compact ring already shows progress.
        VStack(spacing: 0) {
            HStack(spacing: 22) {
                ActivityRoundButton(intent: ResetTimerIntent(), systemImage: "arrow.counterclockwise",
                                    label: String(localized: "Reset Timer"), diameter: 32,
                                    foreground: cream, background: cream.opacity(0.16))
                if state.isRunning && !isStale {
                    ActivityRoundButton(intent: PauseTimerIntent(), systemImage: "pause.fill",
                                        label: String(localized: "Pause"), diameter: 42,
                                        foreground: ink, background: cream)
                } else {
                    ActivityRoundButton(intent: PlayTimerIntent(), systemImage: "play.fill",
                                        label: isStale ? String(localized: "Next", comment: "Live Activity: start next session")
                                                       : String(localized: "Resume"),
                                        diameter: 42, foreground: ink, background: cream)
                }
                ActivityRoundButton(intent: SkipTimerIntent(), systemImage: "forward.end.fill",
                                    label: String(localized: "Skip Session"), diameter: 32,
                                    foreground: cream, background: cream.opacity(0.16))
            }
        }
    }
}
