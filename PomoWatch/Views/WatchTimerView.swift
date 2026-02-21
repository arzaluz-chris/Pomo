// PomoWatch/Views/WatchTimerView.swift

import SwiftUI

struct WatchTimerView: View {
    @StateObject private var viewModel = WatchTimerViewModel()

    var body: some View {
        if #available(watchOS 26, *) {
            glassTimerView
        } else {
            standardTimerView
        }
    }

    // MARK: - watchOS 26+ Glassmorphism Design

    @available(watchOS 26, *)
    private var glassTimerView: some View {
        VStack(spacing: 4) {
            // Timer Circle
            ZStack {
                WatchCircularProgressView(progress: viewModel.progress)

                VStack(spacing: 1) {
                    Text(viewModel.timeString)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)

                    Text(viewModel.currentType.displayName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: Constants.WatchUI.timerCircleSize, height: Constants.WatchUI.timerCircleSize)

            // Session progress
            sessionDotsView

            // Controls
            HStack(spacing: 8) {
                // Reset button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.resetTimer()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .tint(.gray)

                // Play/Pause button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.toggleTimer()
                    }
                }) {
                    Image(systemName: viewModel.isActive ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
                .tint(.pomoPrimary)

                // Skip button (only when active)
                if viewModel.isActive {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.skipSession()
                        }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.body)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .transition(.opacity.combined(with: .scale))
                } else {
                    // Settings button when idle
                    NavigationLink(destination: WatchSettingsView()) {
                        Image(systemName: "gear")
                            .font(.body)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                }
            }
        }
        .navigationTitle("Pomo")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pre-watchOS 26 Standard Design

    private var standardTimerView: some View {
        VStack(spacing: 4) {
            // Timer Circle
            ZStack {
                WatchCircularProgressView(progress: viewModel.progress)

                VStack(spacing: 1) {
                    Text(viewModel.timeString)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.pomoPrimary)

                    Text(viewModel.currentType.displayName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: Constants.WatchUI.timerCircleSize, height: Constants.WatchUI.timerCircleSize)

            // Session progress
            sessionDotsView

            // Controls
            HStack(spacing: 8) {
                Button(action: {
                    viewModel.resetTimer()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .tint(.gray)

                Button(action: {
                    viewModel.toggleTimer()
                }) {
                    Image(systemName: viewModel.isActive ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
                .tint(.pomoPrimary)

                if viewModel.isActive {
                    Button(action: {
                        viewModel.skipSession()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.body)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .transition(.opacity.combined(with: .scale))
                } else {
                    NavigationLink(destination: WatchSettingsView()) {
                        Image(systemName: "gear")
                            .font(.body)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                }
            }
        }
        .navigationTitle("Pomo")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Shared Components

    private var sessionDotsView: some View {
        HStack(spacing: 3) {
            let total = UserDefaults.standard.integer(forKey: Constants.UserDefaults.sessionsUntilLongBreak)
            let sessionsCount = total > 0 ? total : Constants.Defaults.sessionsUntilLongBreak
            ForEach(0..<sessionsCount, id: \.self) { index in
                Circle()
                    .fill(index < viewModel.completedSessions ? Color.pomoPrimary : Color.gray.opacity(0.3))
                    .frame(width: 5, height: 5)
            }
        }
    }
}
