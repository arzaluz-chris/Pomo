// WeeklyChart.swift

import SwiftUI
import Charts

struct WeeklyChart: View {
    let data: [DailyStats]
    
    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Día", item.dayName),
                y: .value("Pomodoros", item.pomodoros)
            )
            .foregroundStyle(Color.accentColor)
            .cornerRadius(8)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let day = value.as(String.self) {
                        Text(day)
                            .font(.caption)
                    }
                }
            }
        }
    }
}

struct DailyStats: Identifiable {
    let id = UUID()
    let date: Date
    let pomodoros: Int
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }
}

#Preview {
    WeeklyChart(data: [
        DailyStats(date: Date(), pomodoros: 5),
        DailyStats(date: Date().addingTimeInterval(-86400), pomodoros: 8),
        DailyStats(date: Date().addingTimeInterval(-172800), pomodoros: 3)
    ])
    .frame(height: 200)
    .padding()
}
