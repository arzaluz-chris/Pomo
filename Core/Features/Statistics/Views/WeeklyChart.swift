// WeeklyChart.swift

import SwiftUI
import Charts

struct WeeklyChart: View {
    let data: [DailyStats]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value(String(localized: "Día"), item.date, unit: .day),
                y: .value("Pomodoros", item.pomodoros),
                width: .ratio(0.55)
            )
            .foregroundStyle(PomoPalette.focus.opacity(Calendar.current.isDateInToday(item.date) ? 1 : 0.45))
            .clipShape(Capsule())
            .accessibilityLabel(item.date.formatted(.dateTime.weekday(.wide)))
            .accessibilityValue("\(item.pomodoros) pomodoros")
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(PomoPalette.hairline)
                AxisValueLabel()
            }
        }
    }
}

struct DailyStats: Identifiable {
    let id = UUID()
    let date: Date
    let pomodoros: Int
}

#Preview {
    WeeklyChart(data: (0..<7).map {
        DailyStats(date: Calendar.current.date(byAdding: .day, value: -6 + $0, to: Date())!, pomodoros: [2, 5, 0, 3, 6, 1, 4][$0])
    })
    .frame(height: 200)
    .padding()
}
