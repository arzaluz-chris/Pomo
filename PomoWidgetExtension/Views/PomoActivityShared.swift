// PomoActivityShared.swift

import SwiftUI
import WidgetKit
import AppIntents

extension PomoActivityAttributes.ContentState {
    var type: TimerType { TimerType(rawValue: timerType) ?? .work }
    var isWorkSession: Bool { type == .work }

    /// Field color of the session (Lock Screen background, primary icons).
    var tint: Color { type.tint }

    /// Brighter version of the session color for the black Dynamic Island.
    var islandTint: Color {
        switch type {
        case .work: return Color(pomoHex: 0xFF7A66)
        case .shortBreak: return Color(pomoHex: 0x45D1BF)
        case .longBreak: return Color(pomoHex: 0x9095F7)
        }
    }

    /// Interval the live ring and countdown animate over (pauses already excluded).
    var countdownInterval: ClosedRange<Date>? {
        guard isRunning, let endTime else { return nil }
        let start = endTime.addingTimeInterval(-Double(max(totalDuration, timeRemaining, 1)))
        return start...endTime
    }

    var formattedRemaining: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }
}

/// Session glyph: the Pomo tomato for focus, the break symbol otherwise.
struct SessionIcon: View {
    let state: PomoActivityAttributes.ContentState
    var size: CGFloat = 16
    var color: Color? = nil

    var body: some View {
        if state.isWorkSession {
            PomoMark(tint: color ?? state.islandTint, leafTint: state.type.accent, showsDial: size >= 28)
                .frame(width: size, height: size)
        } else {
            Image(systemName: state.type.symbolName)
                .font(.system(size: size * 0.8, weight: .bold))
                .foregroundStyle(color ?? state.islandTint)
                .accessibilityHidden(true)
        }
    }
}

/// Progress ring that keeps moving on its own while the session runs (no app updates needed).
struct ActivityProgressRing: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool
    var color: Color
    var track: Color
    var lineWidth: CGFloat = 4

    var body: some View {
        if let interval = state.countdownInterval, !isStale {
            ProgressView(timerInterval: interval, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(color)
        } else {
            ZStack {
                Circle().stroke(track, lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: isStale ? 1 : CGFloat(state.progress))
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

/// Remaining time, counting down live while running.
struct ActivityCountdownText: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        if isStale {
            Text(String(localized: "Done", comment: "Live Activity: session finished"))
        } else if let interval = state.countdownInterval {
            Text(timerInterval: Date()...interval.upperBound, countsDown: true)
        } else {
            Text(state.formattedRemaining)
        }
    }
}

/// Passes whether the Dynamic Island is narrower than usual (iPhone Duo, landscape, or
/// several Live Activities at once; iOS 27+).
struct IslandWidthReader<Content: View>: View {
    @ViewBuilder var content: (_ isLimited: Bool) -> Content

    var body: some View {
        if #available(iOS 27, *) {
            LimitedWidthReader(content: content)
        } else {
            content(false)
        }
    }
}

@available(iOS 27, *)
private struct LimitedWidthReader<Content: View>: View {
    @Environment(\.isDynamicIslandLimitedInWidth) private var isLimited
    let content: (Bool) -> Content

    var body: some View { content(isLimited) }
}

/// Round control button used in the Live Activity.
struct ActivityRoundButton<I: AppIntent>: View {
    let intent: I
    let systemImage: String
    let label: String
    var diameter: CGFloat = 34
    var foreground: Color
    var background: Color

    var body: some View {
        Button(intent: intent) {
            Image(systemName: systemImage)
                .font(.system(size: diameter * 0.38, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: diameter, height: diameter)
                .background(background, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

