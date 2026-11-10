// PomoWatch/Views/WatchTimerView.swift

import SwiftUI

struct WatchTimerView: View {
    @StateObject private var viewModel = WatchTimerViewModel()
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tint: Color {
        viewModel.currentType == .work ? .pomoPrimary : .pomoSecondary
    }

    var body: some View {
        VStack(spacing: 4) {
            timerRing
                .frame(width: Constants.WatchUI.timerCircleSize, height: Constants.WatchUI.timerCircleSize)

            cycleDots

            controls
        }
        .navigationTitle("Pomo")
        .navigationBarTitleDisplayMode(.inline)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.state.phase)
    }

    // MARK: - Ring

    private var timerRing: some View {
        ZStack {
            WatchCircularProgressView(progress: viewModel.progress, tint: tint)

            VStack(spacing: 1) {
                timeText
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.primary)

                Text(viewModel.isPaused
                     ? String(localized: "Paused", comment: "Timer state label")
                     : viewModel.currentType.displayName)
                    .font(.system(size: 10, weight: viewModel.isPaused ? .semibold : .regular))
                    .foregroundStyle(viewModel.isPaused ? tint : .secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.currentType.displayName)
        .accessibilityValue(accessibilityTimeValue)
    }

    /// In always-on mode the app is updated rarely, so let the system draw the countdown.
    @ViewBuilder
    private var timeText: some View {
        if isLuminanceReduced, viewModel.isActive, let endDate = viewModel.state.endDate, endDate > Date() {
            Text(timerInterval: Date()...endDate, countsDown: true)
        } else {
            Text(viewModel.timeString)
        }
    }

    private var accessibilityTimeValue: String {
        let remaining = Duration.seconds(viewModel.timeRemaining)
            .formatted(.units(allowed: [.minutes, .seconds], width: .wide))
        if viewModel.isPaused {
            return String(localized: "Paused, \(remaining) remaining", comment: "VoiceOver value of a paused timer")
        }
        return String(localized: "\(remaining) remaining", comment: "VoiceOver value of the timer")
    }

    // MARK: - Cycle

    private var cycleDots: some View {
        let total = max(1, viewModel.settings.sessionsUntilLongBreak)
        let completed = viewModel.completedSessions
        let position = completed == 0 ? 0 : ((completed - 1) % total) + 1

        return HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < position ? Color.pomoPrimary : Color.gray.opacity(0.3))
                    .frame(width: 5, height: 5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(position) of \(total) sessions before the long break",
                                   comment: "VoiceOver label of the session cycle dots"))
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.resetTimer()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.body)
            }
            .buttonStyle(.bordered)
            .tint(.gray)
            .disabled(viewModel.state.isIdle)
            .accessibilityLabel(String(localized: "Reset Timer"))

            Button {
                viewModel.toggleTimer()
            } label: {
                Image(systemName: viewModel.isActive ? "pause.fill" : "play.fill")
                    .font(.title3)
            }
            .buttonStyle(.bordered)
            .tint(tint)
            .accessibilityLabel(viewModel.isActive ? String(localized: "Pause")
                                : viewModel.isPaused ? String(localized: "Resume")
                                : NSLocalizedString("START", comment: "Start button title"))

            if !viewModel.state.isIdle {
                Button {
                    viewModel.skipSession()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
                .transition(.opacity.combined(with: .scale))
                .accessibilityLabel(String(localized: "Skip Session"))
            } else {
                NavigationLink(destination: WatchSettingsView()) {
                    Image(systemName: "gear")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
                .accessibilityLabel(String(localized: "Ajustes"))
            }
        }
    }
}
