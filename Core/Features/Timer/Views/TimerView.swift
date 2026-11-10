// Core/Features/Timer/Views/TimerView.swift

import SwiftUI
import SwiftData

/// Layout of the timer screen for the current device shape.
enum TimerLayout {
    /// iPhone and iPhone Duo outer screen.
    case compact
    /// iPhone Duo inner screen held open like a book (or any wide window): timer panel next to
    /// today's stats, split exactly at the hinge when there is one.
    case wide(split: PomoFold?)
    /// iPhone Duo inner screen with a horizontal hinge (rotated, or half folded like a laptop):
    /// the timer on the top half, the controls on the bottom half.
    case folded(top: CGFloat, gap: CGFloat)
}

struct TimerView: View {
    var layout: TimerLayout = .compact
    @Binding var selectedTab: Int

    @EnvironmentObject private var viewModel: TimerViewModel

    var body: some View {
        switch layout {
        case .compact: CompactTimerLayout()
        case .wide(let split): WideTimerLayout(selectedTab: $selectedTab, split: split)
        case .folded(let top, let gap): FoldedTimerLayout(top: top, gap: gap)
        }
    }
}

// MARK: - Shared pieces

/// Strings and values every layout shows.
@MainActor
private struct TimerPresentation {
    let viewModel: TimerViewModel

    var type: TimerType { viewModel.currentType }
    var tint: Color { type.tint }

    var cyclePosition: (current: Int, total: Int) {
        let total = max(1, viewModel.settings.sessionsUntilLongBreak)
        let completed = viewModel.completedSessions
        // The running focus session counts as the next one in the cycle
        let done = completed == 0 ? 0 : ((completed - 1) % total) + 1
        let current = type == .work && !viewModel.state.isIdle ? (done % total) + 1 : max(done, 1)
        return (min(current, total), total)
    }

    var pillText: String {
        let cycle = cyclePosition
        switch type {
        case .work:
            return String(localized: "\(type.displayName) · \(cycle.current) of \(cycle.total)", comment: "Mode pill: session type and position in the cycle")
        case .shortBreak, .longBreak:
            let minutes = viewModel.state.plannedDuration(settings: viewModel.settings) / 60
            return "\(type.displayName) · \(minutes) min"
        }
    }

    var subtitle: String {
        if viewModel.isPaused {
            return String(localized: "Paused", comment: "Timer state label")
        }
        if viewModel.isActive, let endDate = viewModel.state.endDate {
            let time = endDate.formatted(date: .omitted, time: .shortened)
            if type == .work {
                return String(localized: "Ends at \(time)", comment: "Running timer subtitle with the end time")
            }
            return String(localized: "Back to work at \(time)", comment: "Running break subtitle with the end time")
        }
        return String(localized: "Ready", comment: "Timer idle subtitle")
    }

    var primaryLabel: String {
        if viewModel.isActive { return NSLocalizedString("PAUSE", comment: "Pause button title") }
        if viewModel.isPaused { return NSLocalizedString("RESUME", comment: "Resume button title") }
        return NSLocalizedString("START", comment: "Start button title")
    }

    var accessibilityTimeValue: String {
        let remaining = Duration.seconds(viewModel.timeRemaining)
            .formatted(.units(allowed: [.minutes, .seconds], width: .wide))
        if viewModel.isPaused {
            return String(localized: "Paused, \(remaining) remaining", comment: "VoiceOver value of a paused timer")
        }
        return String(localized: "\(remaining) remaining", comment: "VoiceOver value of the timer")
    }
}

/// Session type picker (idle) or the current session's pill.
private struct ModeControl: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    @Namespace private var selection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let presentation = TimerPresentation(viewModel: viewModel)
        if viewModel.state.isIdle {
            HStack(spacing: 2) {
                ForEach(TimerType.allCases, id: \.self) { type in
                    let isSelected = viewModel.currentType == type
                    Button {
                        withAnimation(reduceMotion ? nil : .snappy) { viewModel.changeTimerType(to: type) }
                    } label: {
                        Text(type.displayName)
                            .font(.pomoRounded(.subheadline))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(isSelected ? type.tint : PomoPalette.cream)
                            .padding(.horizontal, PomoSpace.s)
                            .frame(minHeight: 36)
                            .background {
                                if isSelected {
                                    Capsule().fill(PomoPalette.cream)
                                        .matchedGeometryEffect(id: "mode", in: selection)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(4)
            .background(PomoPalette.ink.opacity(0.22), in: Capsule())
        } else {
            PomoFieldPill(text: presentation.pillText)
        }
    }
}

/// Big time, with its subtitle.
private struct TimeBlock: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    var size: CGFloat
    var subtitleFont: Font = .pomoRounded(.headline, weight: .bold)

    var body: some View {
        let presentation = TimerPresentation(viewModel: viewModel)
        VStack(spacing: 6) {
            Text(viewModel.timeString)
                .font(.pomoNumber(size: size))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .contentTransition(.numericText(countsDown: true))
                .foregroundStyle(PomoPalette.cream)
            Text(presentation.subtitle)
                .font(subtitleFont)
                .foregroundStyle(presentation.type.onFieldSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.type.displayName)
        .accessibilityValue(presentation.accessibilityTimeValue)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Reset, play/pause and skip.
private struct ControlsRow: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    var primaryDiameter: CGFloat = 88
    var secondaryDiameter: CGFloat = 60
    var spacing: CGFloat = 28

    var body: some View {
        let presentation = TimerPresentation(viewModel: viewModel)
        HStack(spacing: spacing) {
            PomoRoundButton(systemImage: "arrow.counterclockwise", label: String(localized: "Reiniciar"),
                            diameter: secondaryDiameter) { viewModel.resetTimer() }
                .disabled(viewModel.state.isIdle)
                .opacity(viewModel.state.isIdle ? 0.5 : 1)
            PomoRoundButton(systemImage: viewModel.isActive ? "pause.fill" : "play.fill",
                            label: presentation.primaryLabel, role: .primary,
                            diameter: primaryDiameter) { viewModel.toggleTimer() }
            PomoRoundButton(systemImage: "forward.end.fill", label: String(localized: "Saltar"),
                            diameter: secondaryDiameter) { viewModel.skipSession() }
                .disabled(viewModel.state.isIdle)
                .opacity(viewModel.state.isIdle ? 0.5 : 1)
        }
    }
}

/// Header on the colored field: mark, name and today's count.
private struct FieldHeader: View {
    @EnvironmentObject private var viewModel: TimerViewModel

    var body: some View {
        HStack {
            HStack(spacing: PomoSpace.xs) {
                PomoMark(tint: PomoPalette.cream, leafTint: viewModel.currentType.accent, showsDial: false)
                    .frame(width: 26, height: 26)
                Text("Pomo")
                    .font(.pomoRounded(.title2, weight: .black))
                    .foregroundStyle(PomoPalette.cream)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer()
            TodayBadge()
        }
    }
}

/// "3 today" badge.
private struct TodayBadge: View {
    @EnvironmentObject private var viewModel: TimerViewModel

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(viewModel.currentType.accent).frame(width: 8, height: 8)
            Text(String(localized: "\(viewModel.completedSessions) today", comment: "Badge: pomodoros completed today"))
                .font(.pomoRounded(.subheadline))
                .monospacedDigit()
        }
        .foregroundStyle(PomoPalette.ink)
        .padding(.horizontal, PomoSpace.s)
        .frame(minHeight: 32)
        .background(PomoPalette.cream, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// The turning dial for the current session.
private struct SessionDial: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    var radiusRatio: CGFloat = 0.82

    var body: some View {
        KitchenDial(remaining: Double(viewModel.timeRemaining),
                    total: Double(viewModel.state.plannedDuration(settings: viewModel.settings)),
                    type: viewModel.currentType,
                    radiusRatio: radiusRatio)
    }
}

// MARK: - Compact (iPhone, iPhone Duo outer screen)

private struct CompactTimerLayout: View {
    @EnvironmentObject private var viewModel: TimerViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var timeSize: CGFloat = 108

    var body: some View {
        GeometryReader { proxy in
            let dialTop = max(proxy.size.height * 0.46, 330)
            ZStack(alignment: .top) {
                viewModel.currentType.tint.ignoresSafeArea()

                // The dial runs edge to edge, under side safe areas too (iPhone Duo's sensor bar)
                GeometryReader { screen in
                    SessionDial()
                        .frame(width: screen.size.width, height: max(0, screen.size.height - dialTop - proxy.safeAreaInsets.top))
                        .offset(y: dialTop + proxy.safeAreaInsets.top)
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    FieldHeader()
                        .padding(.horizontal, PomoSpace.l)
                        .padding(.top, PomoSpace.xs)

                    ModeControl()
                        .padding(.top, PomoSpace.xl)
                        .padding(.horizontal, PomoSpace.m)

                    TimeBlock(size: min(timeSize, proxy.size.width * 0.3))
                        .padding(.top, PomoSpace.m)

                    Spacer(minLength: 0)

                    ControlsRow()
                        .padding(.bottom, PomoSpace.m)
                }
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.4), value: viewModel.currentType)
        .animation(reduceMotion ? nil : .smooth(duration: 0.4), value: viewModel.state.phase)
    }
}

// MARK: - Wide (iPhone Duo inner screen)

private struct WideTimerLayout: View {
    @Binding var selectedTab: Int
    var split: PomoFold?
    @EnvironmentObject private var viewModel: TimerViewModel

    var body: some View {
        if let split, split.axis == .vertical {
            hingeSplit(split)
        } else {
            sideBySide
        }
    }

    /// Open like a book: the colored timer fills the pane before the hinge, today's stats and
    /// the sections sit after it, so nothing crosses the fold.
    private func hingeSplit(_ fold: PomoFold) -> some View {
        HStack(spacing: 0) {
            ZStack(alignment: .top) {
                viewModel.currentType.tint
                GeometryReader { proxy in
                    SessionDial(radiusRatio: 0.8)
                        .frame(height: proxy.size.height * 0.5)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                VStack(spacing: 0) {
                    ModeControl()
                        .padding(.top, PomoSpace.l)
                        .padding(.horizontal, PomoSpace.s)
                    TimeBlock(size: min(104, fold.before * 0.24))
                        .padding(.top, PomoSpace.s)
                    Spacer(minLength: 0)
                    ControlsRow(primaryDiameter: 84, secondaryDiameter: 58, spacing: 24)
                        .padding(.bottom, PomoSpace.l)
                }
            }
            .frame(width: fold.before)
            .ignoresSafeArea()

            Rectangle()
                .fill(PomoPalette.hairline)
                .frame(width: 2)
                .frame(width: fold.gap)
                .accessibilityHidden(true)

            ScrollView {
                VStack(alignment: .leading, spacing: PomoSpace.m) {
                    HStack {
                        PomoMark(tint: viewModel.currentType.tint, leafTint: viewModel.currentType.accent, showsDial: false)
                            .frame(width: 28, height: 28)
                        Text("Pomo")
                            .font(.pomoRounded(.title2, weight: .black))
                            .foregroundStyle(PomoPalette.inkText)
                        Spacer()
                    }
                    PomoTabBar(selection: $selectedTab, tint: viewModel.currentType.tint, showsAllTitles: true)
                    TodaySummary(style: .column)
                }
                .padding(.horizontal, PomoSpace.l)
                .padding(.vertical, PomoSpace.m)
            }
            .frame(maxWidth: .infinity)
            .background { PomoPage() }
        }
        .background { PomoPage() }
    }

    private var sideBySide: some View {
        VStack(spacing: PomoSpace.l) {
            HStack {
                HStack(spacing: PomoSpace.xs) {
                    PomoMark(tint: viewModel.currentType.tint, leafTint: viewModel.currentType.accent, showsDial: false)
                        .frame(width: 30, height: 30)
                    Text("Pomo")
                        .font(.pomoRounded(.title2, weight: .black))
                        .foregroundStyle(PomoPalette.inkText)
                }
                Spacer()
                PomoTabBar(selection: $selectedTab, tint: viewModel.currentType.tint, showsAllTitles: true)
                    .fixedSize()
            }

            HStack(alignment: .top, spacing: PomoSpace.l - 4) {
                timerPanel
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1.3)
                TodaySummary(style: .column)
                    .frame(maxWidth: 260)
            }
        }
        .padding(.horizontal, PomoSpace.l + 6)
        .padding(.top, PomoSpace.xs)
        .padding(.bottom, PomoSpace.m)
        .background { PomoPage() }
    }

    private var timerPanel: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                viewModel.currentType.tint
                SessionDial(radiusRatio: 0.78)
                    .frame(height: proxy.size.height * 0.62)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                VStack(spacing: 0) {
                    ModeControl()
                        .padding(.top, PomoSpace.l)
                        .padding(.horizontal, PomoSpace.s)
                    TimeBlock(size: min(104, proxy.size.width * 0.3))
                        .padding(.top, PomoSpace.m)
                    Spacer(minLength: 0)
                    ControlsRow(primaryDiameter: 84, secondaryDiameter: 58, spacing: 24)
                        .padding(.bottom, PomoSpace.l)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: PomoRadius.xl, style: .continuous))
        }
    }
}

// MARK: - Folded (iPhone Duo half folded)

private struct FoldedTimerLayout: View {
    /// Height of the half above the hinge (measured by the system) and the hinge itself.
    var top: CGFloat
    var gap: CGFloat
    @EnvironmentObject private var viewModel: TimerViewModel

    var body: some View {
        GeometryReader { proxy in
            let upper = top
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    viewModel.currentType.tint
                    SessionDial(radiusRatio: 0.42)
                        .frame(height: upper * 0.24)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    VStack(spacing: PomoSpace.s) {
                        ModeControl()
                        TimeBlock(size: min(128, upper * 0.42), subtitleFont: .pomoRounded(.title3, weight: .bold))
                    }
                    .padding(.top, PomoSpace.l)
                }
                .frame(height: upper)
                .clipped()

                Rectangle().fill(PomoPalette.hairline).frame(height: 2).frame(height: gap)
                    .frame(maxWidth: .infinity)
                    .background(PomoPalette.background)
                    .accessibilityHidden(true)

                HStack(spacing: PomoSpace.xl) {
                    ControlsRow(primaryDiameter: 112, secondaryDiameter: 72, spacing: 28)
                    TodaySummary(style: .rows)
                        .frame(maxWidth: 360)
                }
                .padding(.horizontal, PomoSpace.xxl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background { PomoPage() }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Today summary (Duo layouts)

/// Today's pomodoros, focus time, streak and (in a column) the week.
struct TodaySummary: View {
    enum Style { case column, rows }
    var style: Style

    @StateObject private var stats = StatisticsViewModel()
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var timer: TimerViewModel

    var body: some View {
        Group {
            switch style {
            case .column: column
            case .rows: rows
            }
        }
        .task(id: timer.completedSessions) {
            stats.dataService.setModelContext(modelContext)
            await stats.loadData()
        }
    }

    private var streakText: String {
        "\(stats.currentStreak) \(stats.currentStreak == 1 ? String(localized: "día") : String(localized: "días"))"
    }

    private var column: some View {
        VStack(alignment: .leading, spacing: PomoSpace.s) {
            Text("Hoy")
                .font(.pomoRounded(.title3, weight: .black))
                .foregroundStyle(PomoPalette.inkText)
                .accessibilityAddTraits(.isHeader)
            PomoStatTile(value: "\(stats.todayPomodoros)", label: String(localized: "Pomodoros"), tint: PomoPalette.focus)
            PomoStatTile(value: stats.todayTimeString, label: String(localized: "Tiempo total"), tint: PomoPalette.shortBreak)
            PomoStatTile(value: streakText, label: String(localized: "Racha actual"), tint: PomoPalette.leaf)
            VStack(alignment: .leading, spacing: PomoSpace.s) {
                Text("Esta semana")
                    .font(.pomoRounded(.subheadline, weight: .black))
                    .foregroundStyle(PomoPalette.inkText)
                WeeklyChart(data: stats.weeklyData, compact: true)
                    .frame(minHeight: 110)
            }
            .pomoCard()
        }
    }

    private var rows: some View {
        VStack(spacing: PomoSpace.s) {
            row(String(localized: "Pomodoros"), "\(stats.todayPomodoros)", PomoPalette.focus)
            row(String(localized: "Tiempo total"), stats.todayTimeString, PomoPalette.shortBreak)
            row(String(localized: "Racha actual"), streakText, PomoPalette.leaf)
        }
    }

    private func row(_ label: String, _ value: String, _ tint: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PomoPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: PomoSpace.xs)
            Text(value)
                .font(.pomoRounded(.title2, weight: .black))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(tint)
        }
        .pomoCard(padding: PomoSpace.s + 2)
        .accessibilityElement(children: .combine)
    }
}
