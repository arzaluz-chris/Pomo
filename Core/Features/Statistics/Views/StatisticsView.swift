// StatisticsView.swift

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Today's Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hoy")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 40) {
                            StatCard(
                                emoji: "🍅",
                                value: "\(viewModel.todayPomodoros)",
                                label: String(localized: "Pomodoros")
                            )
                            
                            StatCard(
                                emoji: "⏱️",
                                value: viewModel.todayTimeString,
                                label: String(localized: "Tiempo total")
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Weekly Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Esta semana")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        WeeklyChart(data: viewModel.weeklyData)
                            .frame(height: 200)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Streak
                    if viewModel.currentStreak > 0 {
                        HStack {
                            Text("🔥")
                                .font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text("Racha actual")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(viewModel.currentStreak) \(viewModel.currentStreak == 1 ? String(localized: "día") : String(localized: "días"))")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.large)
            .task {
                viewModel.dataService.setModelContext(modelContext)
                await viewModel.loadData()
            }
            .onAppear {
                // Recargar datos cada vez que aparezca la vista
                Task {
                    await viewModel.loadData()
                }
            }
        }
    }
}

struct StatCard: View {
    let emoji: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.largeTitle)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: TimerSession.self, inMemory: true)
}
