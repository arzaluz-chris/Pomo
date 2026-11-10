// Core/Features/Timer/Views/TimerView.swift

import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionAnimation

    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize: CGFloat = 52

    private var tint: Color { viewModel.currentType.tint }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                if viewModel.state.isIdle {
                    header
                        .padding(.top, 24)
                        .transition(.opacity)
                }

                Spacer(minLength: 12)

                if viewModel.state.isIdle {
                    typeSelector
                        .transition(.opacity)
                    Spacer(minLength: 12)
                }

                timerRing

                cycleIndicator
                    .padding(.top, 20)

                Spacer(minLength: 12)

                controls
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 24)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: viewModel.state.phase)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: viewModel.currentType)
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            colors: viewModel.state.isRunning
                ? [tint.opacity(0.45), tint.opacity(0.2), Color.pomoBackground]
                : [Color.pomoPrimary.opacity(0.25), Color.pomoSecondary.opacity(0.3), .blue.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blur(radius: reduceMotion ? 0 : 60)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image("AppIcon-Symbol")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)

            Text("Pomo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Session type

    private var typeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimerType.allCases, id: \.self) { type in
                let isSelected = viewModel.currentType == type
                Button {
                    withAnimation(reduceMotion ? nil : .interactiveSpring(response: 0.5, dampingFraction: 0.7)) {
                        viewModel.changeTimerType(to: type)
                    }
                } label: {
                    Text(type.displayName)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(isSelected ? type.tint : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(.thickMaterial)
                                    .shadow(color: .black.opacity(0.08), radius: 2)
                                    .matchedGeometryEffect(id: "selection", in: selectionAnimation)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .pomoGlass(in: Capsule())
        .padding(.horizontal, 24)
    }

    // MARK: - Ring

    private var timerRing: some View {
        ZStack {
            CircularProgressView(progress: viewModel.progress, tint: tint)

            VStack(spacing: 6) {
                Text(viewModel.timeString)
                    .font(.system(size: timeFontSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText(countsDown: true))
                    .foregroundStyle(.primary)

                if viewModel.isPaused {
                    Label(String(localized: "Paused", comment: "Timer state label"), systemImage: "pause.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                } else {
                    Text(viewModel.currentType.displayName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(28)
        }
        .padding(20)
        .frame(maxWidth: 300, maxHeight: 300)
        .aspectRatio(1, contentMode: .fit)
        .pomoGlass(in: Circle())
        .padding(.horizontal, 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.currentType.displayName)
        .accessibilityValue(accessibilityTimeValue)
        .accessibilityAddTraits(.updatesFrequently)
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

    /// Work sessions completed in the current cycle (filled dots) before the long break.
    private var cycleIndicator: some View {
        let total = max(1, viewModel.settings.sessionsUntilLongBreak)
        let completed = viewModel.completedSessions
        let position = completed == 0 ? 0 : ((completed - 1) % total) + 1

        return HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < position ? Color.pomoPrimary : Color.primary.opacity(0.15))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(position) of \(total) sessions before the long break",
                                   comment: "VoiceOver label of the session cycle dots"))
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 16) {
            Button {
                viewModel.toggleTimer()
            } label: {
                Label(primaryButtonTitle, systemImage: viewModel.isActive ? "pause.fill" : "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: Constants.UI.buttonHeight)
            }
            .pomoProminentButton(tint: tint)

            HStack(spacing: 16) {
                Button {
                    viewModel.resetTimer()
                } label: {
                    Label("Reiniciar", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .disabled(viewModel.state.isIdle)

                if !viewModel.state.isIdle {
                    Button {
                        viewModel.skipSession()
                    } label: {
                        Label("Saltar", systemImage: "forward.fill")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .pomoSecondaryButtons()
        }
    }

    private var primaryButtonTitle: String {
        if viewModel.isActive {
            return NSLocalizedString("PAUSE", comment: "Pause button title")
        }
        if viewModel.isPaused {
            return NSLocalizedString("RESUME", comment: "Resume button title")
        }
        return NSLocalizedString("START", comment: "Start button title")
    }
}

// MARK: - Styling helpers

extension TimerType {
    /// Mode color: tomato for focus, teal for breaks.
    var tint: Color {
        self == .work ? .pomoPrimary : .pomoSecondary
    }
}

private extension View {
    /// Liquid Glass on iOS 26, material before.
    @ViewBuilder
    func pomoGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    @ViewBuilder
    func pomoProminentButton(tint: Color) -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glassProminent)
                .tint(tint)
        } else {
            self.buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(tint)
                .shadow(color: tint.opacity(0.4), radius: 10, y: 5)
        }
    }

    @ViewBuilder
    func pomoSecondaryButtons() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glass)
                .tint(.primary)
        } else {
            self.buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.primary)
        }
    }
}
