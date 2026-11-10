// Core/Features/Timer/Views/TimerView.swift

import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selection

    @ScaledMetric(relativeTo: .largeTitle) private var timeFontSize: CGFloat = 64

    private var tint: Color { viewModel.currentType.tint }

    var body: some View {
        ZStack {
            PomoScreenBackground(tint: tint, intensity: viewModel.isActive ? 0.24 : 0.14)

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, PomoSpace.l)
                    .padding(.top, PomoSpace.s)

                Spacer(minLength: PomoSpace.m)

                modeControl
                    .padding(.horizontal, PomoSpace.l)

                Spacer(minLength: PomoSpace.m)

                timerRing
                    .padding(.horizontal, PomoSpace.xxl)

                cycleIndicator
                    .padding(.top, PomoSpace.l)

                Spacer(minLength: PomoSpace.m)

                controls
                    .padding(.horizontal, PomoSpace.l)
                    .padding(.bottom, PomoSpace.l)
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.45), value: viewModel.state.phase)
        .animation(reduceMotion ? nil : .smooth(duration: 0.45), value: viewModel.currentType)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: PomoSpace.xs) {
            PomoMark(tint: PomoPalette.focus, showsDial: false)
                .frame(width: 26, height: 26)
            Text("Pomo")
                .font(.pomoRounded(.title2, weight: .bold))
            Spacer()
            if viewModel.completedSessions > 0 {
                Label {
                    Text("\(viewModel.completedSessions)")
                        .font(.pomoRounded(.subheadline))
                        .monospacedDigit()
                } icon: {
                    PomoMark(showsDial: false).frame(width: 16, height: 16)
                }
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, PomoSpace.s)
                .padding(.vertical, PomoSpace.xs)
                .pomoGlass(in: Capsule())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "\(viewModel.completedSessions) pomodoros today", comment: "Widget: pomodoros today"))
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Mode

    /// Session type picker while idle; the running session's label otherwise (keeps the layout still).
    @ViewBuilder
    private var modeControl: some View {
        if viewModel.state.isIdle {
            HStack(spacing: 0) {
                ForEach(TimerType.allCases, id: \.self) { type in
                    let isSelected = viewModel.currentType == type
                    Button {
                        withAnimation(reduceMotion ? nil : .snappy) {
                            viewModel.changeTimerType(to: type)
                        }
                    } label: {
                        Text(type.displayName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(isSelected ? type.tint : .secondary)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(PomoPalette.surface)
                                        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                                        .matchedGeometryEffect(id: "mode", in: selection)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(PomoSpace.xxs)
            .pomoGlass(in: Capsule())
            .frame(maxWidth: 380)
        } else {
            Label(viewModel.currentType.displayName, systemImage: viewModel.currentType.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, PomoSpace.m)
                .frame(minHeight: 44)
                .pomoGlass(in: Capsule())
        }
    }

    // MARK: - Ring

    private var timerRing: some View {
        ZStack {
            CircularProgressView(progress: viewModel.progress, tint: tint)

            VStack(spacing: PomoSpace.xs) {
                Text(viewModel.timeString)
                    .font(.pomoNumber(size: timeFontSize))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText(countsDown: true))
                    .foregroundStyle(.primary)

                Group {
                    if viewModel.isPaused {
                        Label(String(localized: "Paused", comment: "Timer state label"), systemImage: "pause.circle.fill")
                            .foregroundStyle(tint)
                    } else if viewModel.isActive {
                        Text(endTimeText)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(String(localized: "Ready", comment: "Timer idle subtitle"))
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline.weight(.medium))
            }
            .padding(PomoSpace.xl)
        }
        .frame(maxWidth: 320)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.currentType.displayName)
        .accessibilityValue(accessibilityTimeValue)
        .accessibilityAddTraits(.updatesFrequently)
    }

    /// "Ends at 10:25" under the running time.
    private var endTimeText: String {
        guard let endDate = viewModel.state.endDate else { return "" }
        return String(localized: "Ends at \(endDate.formatted(date: .omitted, time: .shortened))",
                      comment: "Running timer subtitle with the end time")
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

    /// Focus sessions done in the current cycle, before the long break.
    private var cycleIndicator: some View {
        let total = max(1, viewModel.settings.sessionsUntilLongBreak)
        let completed = viewModel.completedSessions
        let position = completed == 0 ? 0 : ((completed - 1) % total) + 1

        return HStack(spacing: PomoSpace.xs) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < position ? PomoPalette.focus : Color.primary.opacity(0.12))
                    .frame(width: index < position ? 18 : 8, height: 8)
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: position)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(position) of \(total) sessions before the long break",
                                   comment: "VoiceOver label of the session cycle dots"))
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: PomoSpace.s) {
            Button {
                viewModel.toggleTimer()
            } label: {
                Label(primaryButtonTitle, systemImage: viewModel.isActive ? "pause.fill" : "play.fill")
                    .font(.pomoRounded(.headline, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .pomoPrimaryButton(tint: tint)

            HStack(spacing: PomoSpace.s) {
                Button {
                    viewModel.resetTimer()
                } label: {
                    Label("Reiniciar", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .disabled(viewModel.state.isIdle)

                Button {
                    viewModel.skipSession()
                } label: {
                    Label("Saltar", systemImage: "forward.end.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .disabled(viewModel.state.isIdle)
            }
            .font(.subheadline.weight(.semibold))
            .pomoSecondaryButton()
        }
        .frame(maxWidth: 480)
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
