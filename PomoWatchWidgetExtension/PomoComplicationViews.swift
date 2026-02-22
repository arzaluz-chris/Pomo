// PomoWatchWidgetExtension/PomoComplicationViews.swift

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct PomoComplicationEntry: TimelineEntry {
    let date: Date
    let timerType: String
    let timeRemaining: Int
    let isActive: Bool
    let totalDuration: Int
    let endTime: TimeInterval

    var displayName: String {
        switch timerType {
        case "work":
            return String(localized: "Work", comment: "Work session type")
        case "shortBreak":
            return String(localized: "Break", comment: "Short break session type")
        case "longBreak":
            return String(localized: "Long Break", comment: "Long break session type")
        default:
            return timerType
        }
    }

    var shortDisplayName: String {
        switch timerType {
        case "work":
            return String(localized: "Work", comment: "Work session short name")
        case "shortBreak":
            return String(localized: "Break", comment: "Break session short name")
        case "longBreak":
            return String(localized: "Long", comment: "Long break short name")
        default:
            return timerType
        }
    }

    var tintColor: Color {
        switch timerType {
        case "shortBreak", "longBreak":
            return .pomoSecondary
        default:
            return .pomoPrimary
        }
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / Double(totalDuration))
    }

    var timeString: String {
        let minutes = max(0, timeRemaining) / 60
        let seconds = max(0, timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var durationMinutes: Int {
        totalDuration / 60
    }

    var currentTimeRemaining: Int {
        guard isActive else { return timeRemaining }
        let remaining = Int(endTime - Date().timeIntervalSince1970)
        return max(0, remaining)
    }
}

// MARK: - Timeline Provider

struct PomoComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> PomoComplicationEntry {
        PomoComplicationEntry(
            date: Date(),
            timerType: "work",
            timeRemaining: 25 * 60,
            isActive: false,
            totalDuration: 25 * 60,
            endTime: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PomoComplicationEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PomoComplicationEntry>) -> Void) {
        let entry = currentEntry()

        if entry.isActive {
            // Generate entries for each minute remaining
            var entries: [PomoComplicationEntry] = []
            let remaining = entry.currentTimeRemaining

            for offset in stride(from: 0, through: remaining, by: 60) {
                let entryDate = Date().addingTimeInterval(Double(offset))
                let entryRemaining = remaining - offset
                entries.append(PomoComplicationEntry(
                    date: entryDate,
                    timerType: entry.timerType,
                    timeRemaining: entryRemaining,
                    isActive: true,
                    totalDuration: entry.totalDuration,
                    endTime: entry.endTime
                ))
            }

            // Add final entry when timer completes
            let completionDate = Date().addingTimeInterval(Double(remaining))
            entries.append(PomoComplicationEntry(
                date: completionDate,
                timerType: entry.timerType,
                timeRemaining: 0,
                isActive: false,
                totalDuration: entry.totalDuration,
                endTime: entry.endTime
            ))

            completion(Timeline(entries: entries, policy: .atEnd))
        } else {
            // Not active: refresh in 15 minutes
            let nextUpdate = Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func currentEntry() -> PomoComplicationEntry {
        let defaults = UserDefaults.standard
        let timerType = defaults.string(forKey: "watch_complication_timerType") ?? "work"
        let timeRemaining = defaults.integer(forKey: "watch_complication_timeRemaining")
        let isActive = defaults.bool(forKey: "watch_complication_isActive")
        let totalDuration = defaults.integer(forKey: "watch_complication_totalDuration")
        let endTime = defaults.double(forKey: "watch_complication_endTime")

        let actualRemaining: Int
        if isActive && endTime > 0 {
            actualRemaining = max(0, Int(endTime - Date().timeIntervalSince1970))
        } else {
            actualRemaining = timeRemaining
        }

        return PomoComplicationEntry(
            date: Date(),
            timerType: timerType,
            timeRemaining: actualRemaining,
            isActive: isActive,
            totalDuration: totalDuration > 0 ? totalDuration : Constants.Defaults.workDuration,
            endTime: endTime
        )
    }
}

// MARK: - Circular Complication

struct PomoCircularComplication: Widget {
    let kind = "PomoCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomoComplicationProvider()) { entry in
            ZStack {
                AccessoryWidgetBackground()

                if entry.isActive {
                    Gauge(value: entry.progress) {
                        Image(systemName: "timer")
                    } currentValueLabel: {
                        Text(entry.timeString)
                            .font(.system(size: 12, design: .rounded))
                            .monospacedDigit()
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(entry.tintColor)
                } else {
                    Gauge(value: 0) {
                        Image(systemName: "timer")
                    } currentValueLabel: {
                        Text("\(entry.durationMinutes)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    } minimumValueLabel: {
                        Text("")
                    } maximumValueLabel: {
                        Text(String(localized: "min", comment: "Minutes abbreviation for complication"))
                            .font(.system(size: 6))
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(.pomoPrimary)
                }
            }
        }
        .configurationDisplayName("Pomo Timer")
        .description(String(localized: "Timer remaining time", comment: "Circular complication description"))
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Inline Complication

struct PomoInlineComplication: Widget {
    let kind = "PomoInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomoComplicationProvider()) { entry in
            if entry.isActive {
                Text("\(Image(systemName: "timer")) \(entry.shortDisplayName) \(entry.timeString)")
                    .monospacedDigit()
            } else {
                Text("\(Image(systemName: "timer")) Pomo · \(entry.durationMinutes) min")
            }
        }
        .configurationDisplayName("Pomo Inline")
        .description(String(localized: "Inline timer status", comment: "Inline complication description"))
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Rectangular Complication

struct PomoRectangularComplication: Widget {
    let kind = "PomoRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomoComplicationProvider()) { entry in
            if entry.isActive {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "timer")
                            .font(.caption2)
                            .foregroundStyle(entry.tintColor)
                        Text(entry.displayName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(entry.timeString)
                            .font(.caption)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    ProgressView(value: entry.progress)
                        .tint(entry.tintColor)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "timer")
                            .font(.caption2)
                            .foregroundStyle(.pomoPrimary)
                        Text("Pomo")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    Text(String(localized: "Ready to focus", comment: "Idle complication state"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ProgressView(value: 0)
                        .tint(.pomoPrimary)
                }
            }
        }
        .configurationDisplayName("Pomo Rectangular")
        .description(String(localized: "Detailed timer status", comment: "Rectangular complication description"))
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Corner Complication

struct PomoCornerComplication: Widget {
    let kind = "PomoCorner"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomoComplicationProvider()) { entry in
            if entry.isActive {
                Text(entry.timeString)
                    .font(.system(size: 14, design: .rounded))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .widgetCurvesContent()
                    .widgetLabel {
                        Gauge(value: entry.progress) {
                            Text(entry.shortDisplayName)
                        }
                        .gaugeStyle(.accessoryLinear)
                        .tint(entry.tintColor)
                    }
            } else {
                Text("\(entry.durationMinutes)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .widgetCurvesContent()
                    .widgetLabel {
                        Text("\(Image(systemName: "timer")) Pomo")
                    }
            }
        }
        .configurationDisplayName("Pomo Corner")
        .description(String(localized: "Corner timer", comment: "Corner complication description"))
        .supportedFamilies([.accessoryCorner])
    }
}
