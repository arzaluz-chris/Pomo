// WeeklyChart.swift

import SwiftUI
import Charts

struct WeeklyChart: View {
    let data: [DailyStats]
    /// Hides the value axis (Duo side panel).
    var compact = false

    var body: some View {
        Chart(data) { item in
            let isToday = Calendar.current.isDateInToday(item.date)
            BarMark(
                x: .value(String(localized: "Día"), item.date, unit: .day),
                y: .value("Pomodoros", item.pomodoros),
                width: .ratio(0.6)
            )
            .foregroundStyle(isToday ? PomoPalette.focus : TimerType.work.wedge)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .accessibilityLabel(item.date.formatted(.dateTime.weekday(.wide)))
            .accessibilityValue("\(item.pomodoros) pomodoros")
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                    .foregroundStyle(PomoPalette.muted)
            }
        }
        .chartYAxis {
            if compact {
                AxisMarks { _ in }
            } else {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(PomoPalette.hairline)
                    AxisValueLabel().foregroundStyle(PomoPalette.muted)
                }
            }
        }
    }
}

struct DailyStats: Identifiable {
    let id = UUID()
    let date: Date
    let pomodoros: Int
}
