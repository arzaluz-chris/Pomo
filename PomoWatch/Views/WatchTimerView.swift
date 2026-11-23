// PomoWatch/Views/WatchTimerView.swift

import SwiftUI

/// Watch timer in the "Cocina" style: the session color fills the screen, the cream kitchen
/// dial turns at the bottom, with round controls on it.
struct WatchTimerView: View {
    @StateObject private var viewModel = WatchTimerViewModel()
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var type: TimerType { viewModel.currentType }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                (isLuminanceReduced ? Color.black : type.tint)
                    .ignoresSafeArea()

                if !isLuminanceReduced {
                    KitchenDial(remaining: Double(viewModel.timeRemaining),
                                total: Double(viewModel.state.plannedDuration(settings: viewModel.settings)),
                                type: type,
                                radiusRatio: 0.95,
                                pointerSpace: 12,
                                showsLabels: false)
                        .frame(height: proxy.size.height * 0.8)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .ignoresSafeArea(edges: .bottom)
                }

                VStack(spacing: 0) {
                    Text(modeText)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(isLuminanceReduced ? type.tint : type.onFieldSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    timeText
                        .font(.pomoNumber(size: 46))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(PomoPalette.cream)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(type.displayName)
                        .accessibilityValue(accessibilityTimeValue)

                    Spacer(minLength: 0)

                    if !isLuminanceReduced {
                        controls
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(destination: WatchSettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(PomoPalette.cream)
                }
                .accessibilityLabel(String(localized: "Ajustes"))
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.state.phase)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: type)
    }

    // MARK: - Pieces

    private var modeText: String {
        if viewModel.isPaused {
            return String(localized: "Paused", comment: "Timer state label") + " · " + type.displayName
        }
        let total = max(1, viewModel.settings.sessionsUntilLongBreak)
        let completed = viewModel.completedSessions
        let done = completed == 0 ? 0 : ((completed - 1) % total) + 1
        if type == .work {
            let current = viewModel.state.isIdle ? max(done, 1) : (done % total) + 1
            return String(localized: "\(type.displayName) · \(min(current, total)) of \(total)",
                          comment: "Mode pill: session type and position in the cycle")
        }
        return type.displayName
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

    private var controls: some View {
        HStack(spacing: 8) {
            roundButton(systemImage: "arrow.counterclockwise", label: String(localized: "Reset Timer"),
                        diameter: 40, primary: false) { viewModel.resetTimer() }
                .disabled(viewModel.state.isIdle)
                .opacity(viewModel.state.isIdle ? 0.5 : 1)
            roundButton(systemImage: viewModel.isActive ? "pause.fill" : "play.fill",
                        label: viewModel.isActive ? String(localized: "Pause")
                            : viewModel.isPaused ? String(localized: "Resume")
                            : NSLocalizedString("START", comment: "Start button title"),
                        diameter: 52, primary: true) { viewModel.toggleTimer() }
            roundButton(systemImage: "forward.end.fill", label: String(localized: "Skip Session"),
                        diameter: 40, primary: false) { viewModel.skipSession() }
                .disabled(viewModel.state.isIdle)
                .opacity(viewModel.state.isIdle ? 0.5 : 1)
        }
        .padding(.bottom, 2)
    }

    private func roundButton(systemImage: String, label: String, diameter: CGFloat, primary: Bool,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: diameter * 0.36, weight: .bold))
                .foregroundStyle(primary ? PomoPalette.cream : PomoPalette.ink)
                .frame(width: diameter, height: diameter)
                .background(primary ? PomoPalette.ink : Color.white, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
