// PomoExpandedViews.swift

import SwiftUI
import WidgetKit
import AppIntents

struct ExpandedCenterView: View {
    let state: PomoActivityAttributes.ContentState

    private var isWorkSession: Bool {
        state.timerType == TimerType.work.rawValue
    }

    private var accentColor: Color {
        isWorkSession ? Color("PomoPrimary") : Color("PomoSecondary")
    }

    var body: some View {
        VStack(spacing: 2) {
            // Session icon + type label
            HStack(spacing: 5) {
                if isWorkSession {
                    Image("PomoIcon")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                Text(state.timerTypeDisplayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Large centered timer
            if state.isRunning, let endTime = state.endTime {
                Text(timerInterval: Date()...endTime, countsDown: true)
                    .monospacedDigit()
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText(countsDown: true))
            } else {
                Text(formatTime(state.timeRemaining))
                    .monospacedDigit()
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

struct ExpandedBottomView: View {
    let state: PomoActivityAttributes.ContentState

    private var isWorkSession: Bool {
        state.timerType == TimerType.work.rawValue
    }

    private var accentColor: Color {
        isWorkSession ? Color("PomoPrimary") : Color("PomoSecondary")
    }

    var body: some View {
        HStack(spacing: 16) {
            // Reset button
            Button(intent: ResetTimerIntent()) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Play/Pause button
            if state.isRunning {
                Button(intent: PauseTimerIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(String(localized: "Pause"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(height: 28)
                    .padding(.horizontal, 16)
                    .background(accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button(intent: PlayTimerIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(String(localized: "Resume"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(height: 28)
                    .padding(.horizontal, 16)
                    .background(accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Skip button
            Button(intent: SkipTimerIntent()) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}
