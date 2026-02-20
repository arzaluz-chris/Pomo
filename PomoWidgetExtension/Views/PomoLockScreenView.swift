// PomoLockScreenView.swift

import SwiftUI
import WidgetKit
import AppIntents

struct PomoLockScreenView: View {
    let state: PomoActivityAttributes.ContentState

    private var isWorkSession: Bool {
        state.timerType == TimerType.work.rawValue
    }

    private var accentColor: Color {
        isWorkSession ? Color("PomoPrimary") : Color("PomoSecondary")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.3), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: CGFloat(state.progress))
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                if isWorkSession {
                    Image("PomoIcon")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
            }

            // Timer + Label
            VStack(alignment: .leading, spacing: 2) {
                if state.isRunning, let endTime = state.endTime {
                    Text(timerInterval: Date()...endTime, countsDown: true)
                        .monospacedDigit()
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                } else {
                    Text(formatTime(state.timeRemaining))
                        .monospacedDigit()
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Text(state.timerTypeDisplayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Controls
            HStack(spacing: 8) {
                Button(intent: ResetTimerIntent()) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                if state.isRunning {
                    Button(intent: PauseTimerIntent()) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(accentColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(intent: PlayTimerIntent()) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(accentColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Button(intent: SkipTimerIntent()) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
