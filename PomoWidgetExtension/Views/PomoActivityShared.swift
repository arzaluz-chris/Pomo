// PomoActivityShared.swift

import SwiftUI
import WidgetKit

extension PomoActivityAttributes.ContentState {
    var isWorkSession: Bool { timerType == TimerType.work.rawValue }

    var tint: Color { isWorkSession ? Color("PomoPrimary") : Color("PomoSecondary") }

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

/// Session icon: the Pomo tomato for focus, a cup for breaks.
struct SessionIcon: View {
    let state: PomoActivityAttributes.ContentState
    var size: CGFloat = 16

    var body: some View {
        if state.isWorkSession {
            Image("PomoIcon")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        } else {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: size * 0.8, weight: .semibold))
                .foregroundStyle(state.tint)
                .accessibilityHidden(true)
        }
    }
}

/// Progress ring that keeps moving on its own while the session runs (no app updates needed).
struct ActivityProgressRing: View {
    let state: PomoActivityAttributes.ContentState
    let isStale: Bool
    var lineWidth: CGFloat = 4

    var body: some View {
        if let interval = state.countdownInterval, !isStale {
            ProgressView(timerInterval: interval, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(state.tint)
        } else {
            ZStack {
                Circle()
                    .stroke(state.tint.opacity(0.3), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: isStale ? 1 : CGFloat(state.progress))
                    .stroke(state.tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
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
