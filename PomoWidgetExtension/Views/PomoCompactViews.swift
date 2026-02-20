// PomoCompactViews.swift

import SwiftUI
import WidgetKit

struct CompactLeadingView: View {
    let state: PomoActivityAttributes.ContentState

    private var isWorkSession: Bool {
        state.timerType == TimerType.work.rawValue
    }

    var body: some View {
        if isWorkSession {
            Image("PomoIcon")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
        } else {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color("PomoSecondary"))
        }
    }
}

struct CompactTrailingView: View {
    let state: PomoActivityAttributes.ContentState

    var body: some View {
        if state.isRunning, let endTime = state.endTime {
            Text(timerInterval: Date()...endTime, countsDown: true)
                .monospacedDigit()
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 56)
        } else {
            Text(formatTime(state.timeRemaining))
                .monospacedDigit()
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 56)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

struct MinimalView: View {
    let state: PomoActivityAttributes.ContentState

    private var isWorkSession: Bool {
        state.timerType == TimerType.work.rawValue
    }

    private var tintColor: Color {
        isWorkSession ? Color("PomoPrimary") : Color("PomoSecondary")
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(tintColor.opacity(0.3), lineWidth: 2)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(state.progress))
                .stroke(tintColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Centered app icon
            if isWorkSession {
                Image("PomoIcon")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(tintColor)
            }
        }
    }
}
