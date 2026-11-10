// PomoExpandedViews.swift
//
// Expanded Dynamic Island: session and time on top, a live progress rule like a flattened
// kitchen-timer dial, and the round controls.

import SwiftUI
import WidgetKit
import AppIntents

struct ExpandedLeadingView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        HStack(spacing: 6) {
            SessionIcon(state: state, size: 18)
            Text(isStale ? String(localized: "Session complete", comment: "Live Activity: session finished")
                         : state.timerTypeDisplayName)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(state.islandTint)
                .lineLimit(1)
        }
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
        .padding(.trailing, 4)
    }
}

struct ExpandedCenterView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        ActivityCountdownText(state: state, isStale: isStale)
            .font(.system(size: 44, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color(pomoHex: 0xFFF4E6))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(state.timerTypeDisplayName)
    }
}

struct ExpandedBottomView: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    private let cream = Color(pomoHex: 0xFFF4E6)
    private let ink = Color(pomoHex: 0x2B1714)

    var body: some View {
        VStack(spacing: 12) {
            ProgressRule(state: state, isStale: isStale)
                .frame(height: 14)
                .padding(.horizontal, 6)

            HStack(spacing: 22) {
                ActivityRoundButton(intent: ResetTimerIntent(), systemImage: "arrow.counterclockwise",
                                    label: String(localized: "Reset Timer"), diameter: 40,
                                    foreground: cream, background: cream.opacity(0.16))
                if state.isRunning && !isStale {
                    ActivityRoundButton(intent: PauseTimerIntent(), systemImage: "pause.fill",
                                        label: String(localized: "Pause"), diameter: 52,
                                        foreground: ink, background: cream)
                } else {
                    ActivityRoundButton(intent: PlayTimerIntent(), systemImage: "play.fill",
                                        label: isStale ? String(localized: "Next", comment: "Live Activity: start next session")
                                                       : String(localized: "Resume"),
                                        diameter: 52, foreground: ink, background: cream)
                }
                ActivityRoundButton(intent: SkipTimerIntent(), systemImage: "forward.end.fill",
                                    label: String(localized: "Skip Session"), diameter: 40,
                                    foreground: cream, background: cream.opacity(0.16))
            }
        }
        .padding(.bottom, 4)
    }
}

/// Live progress with minute ticks, like a kitchen-timer dial laid flat.
struct ProgressRule: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            if let interval = state.countdownInterval, !isStale {
                ProgressView(timerInterval: interval, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.linear)
                .tint(state.islandTint)
            } else {
                ProgressView(value: isStale ? 1 : state.progress)
                    .progressViewStyle(.linear)
                    .tint(state.islandTint)
            }
            Canvas { context, size in
                let minutes = max(1, state.totalDuration / 60)
                let step = minutes > 30 ? 5 : 1
                for minute in stride(from: 0, through: minutes, by: step) {
                    let x = size.width * CGFloat(minute) / CGFloat(minutes)
                    let major = minute % 5 == 0
                    var tick = Path()
                    tick.move(to: CGPoint(x: x, y: size.height))
                    tick.addLine(to: CGPoint(x: x, y: size.height - (major ? 6 : 3)))
                    context.stroke(tick, with: .color(.white.opacity(major ? 0.5 : 0.25)), lineWidth: 1)
                }
            }
            .allowsHitTesting(false)
        }
        .accessibilityHidden(true)
    }
}
