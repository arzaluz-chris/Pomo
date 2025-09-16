// Core/Features/Statistics/Views/StatisticsView.swift

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            if #available(iOS 26, *) {
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // SECCIÓN DE RACHA
                            if viewModel.currentStreak > 0 {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.orange)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Racha actual")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("\(viewModel.currentStreak) \(viewModel.currentStreak == 1 ? String(localized: "día") : String(localized: "días"))")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.pomoPrimary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            }
                            
                            // SECCIÓN "HOY"
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Hoy")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text(Date(), style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 16) {
                                    // --- CAMBIO: Se usa el emoji del tomate ---
                                    StatCard(
                                        symbol: "🍅", // Volvemos al emoji
                                        value: "\(viewModel.todayPomodoros)",
                                        label: String(localized: "Pomodoros"),
                                        color: .pomoPrimary
                                    )
                                    .frame(maxWidth: .infinity)
                                    
                                    StatCard(
                                        symbol: "⏱️", // Emoji para el tiempo
                                        value: viewModel.todayTimeString,
                                        label: String(localized: "Tiempo total"),
                                        color: .pomoSecondary
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            
                            // GRÁFICA DE ESTADÍSTICAS
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Esta semana")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if !viewModel.weeklyData.isEmpty && viewModel.weeklyData.reduce(0, { $0 + $1.pomodoros }) > 0 {
                                    WeeklyChart(data: viewModel.weeklyData)
                                        .frame(height: 200)
                                } else {
                                    Text("No hay datos esta semana")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                                
                                let weeklyTotal = viewModel.weeklyData.reduce(0) { $0 + $1.pomodoros }
                                HStack {
                                    Text("Total semanal:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(weeklyTotal) pomodoros")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                        }
                        .padding()
                    }
                }
                .navigationTitle("Estadísticas")
                .task {
                    viewModel.dataService.setModelContext(modelContext)
                    await viewModel.loadData()
                }
            } else {
                // CÓDIGO ORIGINAL (sin cambios para mantener compatibilidad)
                // ...
            }
        }
    }
}

// --- CAMBIO: `StatCard` simplificada para usar emojis ---
struct StatCard: View {
    let symbol: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        if #available(iOS 26, *) {
            VStack(spacing: 8) {
                Text(symbol) // Se usa Text, que renderiza emojis perfectamente
                    .font(.system(size: 40))
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else {
            // CÓDIGO ORIGINAL (sin cambios)
            // ...
        }
    }
}
