// PomoTodayWidget.swift
//
// Home Screen, Lock Screen and StandBy widget: the running session (live countdown) or,
// when idle, today's focus progress with a button to start a session.

import SwiftUI
import WidgetKit
import AppIntents

struct PomoTodayEntry: TimelineEntry {
    let date: Date
    let state: PomodoroState
    let pomodoros: Int
    let focusMinutes: Int
    let streak: Int

    var isRunning: Bool {
        guard state.isRunning, let endDate = state.endDate else { return false }
        return endDate > date
    }

    var tint: Color { state.type == .work ? Color("PomoPrimary") : Color("PomoSecondary") }

    var countdownInterval: ClosedRange<Date>? {
        guard isRunning, let endDate = state.endDate else { return nil }
        let total = Double(max(state.totalDuration, 1))
        return endDate.addingTimeInterval(-total)...endDate
    }

    static let placeholder = PomoTodayEntry(date: Date(), state: PomodoroState(), pomodoros: 3, focusMinutes: 75, streak: 4)
}

struct PomoTodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> PomoTodayEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (PomoTodayEntry) -> Void) {
        completion(context.isPreview ? .placeholder : entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PomoTodayEntry>) -> Void) {
        let now = Date()
        let current = entry(at: now)
        var entries = [current]
        // When the running session ends, switch to the idle layout
        if current.isRunning, let endDate = current.state.endDate {
            entries.append(entry(at: endDate))
        }
        let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400))
        entries.append(entry(at: midnight))
        completion(Timeline(entries: entries, policy: .after(midnight)))
    }

    private func entry(at date: Date) -> PomoTodayEntry {
        let defaults = UserDefaults(suiteName: Constants.AppGroup.identifier)
        let state = TimerStateStore.appGroup().load() ?? PomodoroState()
        let stats = StatsSnapshot.load(from: defaults)?.values(on: date) ?? (pomodoros: 0, focusSeconds: 0, streak: 0)
        return PomoTodayEntry(date: date, state: state, pomodoros: stats.pomodoros,
                              focusMinutes: stats.focusSeconds / 60, streak: stats.streak)
    }
}

struct PomoTodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Constants.Widgets.todayWidgetKind, provider: PomoTodayProvider()) { entry in
            PomoTodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Pomo")
        .description(LocalizedStringResource("Your current session and today's focus.", comment: "Widget description"))
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct PomoTodayWidgetView: View {
    let entry: PomoTodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .containerBackground(for: .widget) {
                LinearGradient(colors: [entry.tint.opacity(0.25), Color("PomoBackground")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        default: small
        }
    }

    // MARK: Home Screen / StandBy

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.isRunning ? "timer" : "flame.fill")
                    .foregroundStyle(entry.tint)
                Text(entry.isRunning ? entry.state.type.displayName : String(localized: "Today", comment: "Widget: today's stats"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)

            if let interval = entry.countdownInterval {
                Text(timerInterval: entry.date...interval.upperBound, countsDown: true)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                ProgressView(timerInterval: interval, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(entry.tint)
            } else {
                Text("\(entry.pomodoros)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    + Text(" 🍅").font(.title3)
                Text(String(localized: "\(entry.focusMinutes) min focused", comment: "Widget: focus minutes today"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(intent: StartFocusIntent()) {
                    Label(String(localized: "Focus", comment: "Widget button: start focus"), systemImage: "play.fill")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("PomoPrimary"))
            }
        }
    }

    // MARK: Lock Screen

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let interval = entry.countdownInterval {
                ProgressView(timerInterval: interval, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    Image(systemName: "timer")
                }
                .progressViewStyle(.circular)
            } else {
                VStack(spacing: 0) {
                    Text("\(entry.pomodoros)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("🍅").font(.system(size: 10))
                }
            }
        }
        .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let interval = entry.countdownInterval {
                Text(entry.state.type.displayName)
                    .font(.caption.weight(.semibold))
                Text(timerInterval: entry.date...interval.upperBound, countsDown: true)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                ProgressView(timerInterval: interval, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            } else {
                Text("Pomo")
                    .font(.caption.weight(.semibold))
                Text(String(localized: "\(entry.pomodoros) pomodoros today", comment: "Widget: pomodoros today"))
                    .font(.caption)
                Text(String(localized: "\(entry.focusMinutes) min focused", comment: "Widget: focus minutes today"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Group {
            if let interval = entry.countdownInterval {
                Text("\(Image(systemName: "timer")) ") + Text(timerInterval: entry.date...interval.upperBound, countsDown: true)
            } else {
                Text("\(Image(systemName: "timer")) \(entry.pomodoros) 🍅 · \(entry.focusMinutes) min")
            }
        }
    }
}
