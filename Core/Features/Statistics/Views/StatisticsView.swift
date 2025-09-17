// Core/Features/Statistics/Views/StatisticsView.swift

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var backgroundGradient = Gradient(colors: [Color.pomoPrimary.opacity(0.3), Color.pomoSecondary.opacity(0.4), .blue.opacity(0.3)])
    
    var body: some View {
        NavigationView {
            if #available(iOS 26, *) {
                ZStack {
                    // FONDO LÍQUIDO ANIMADO (mismo que TimerView)
                    LinearGradient(
                        gradient: backgroundGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    .blur(radius: 60)
                    .animation(.easeInOut(duration: 3), value: backgroundGradient)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // SECCIÓN DE RACHA
                            if viewModel.currentStreak > 0 {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.orange, .red],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Racha actual")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("\(viewModel.currentStreak) \(viewModel.currentStreak == 1 ? String(localized: "día") : String(localized: "días"))")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.pomoPrimary, .pomoSecondary],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            }
                            
                            // SECCIÓN "HOY"
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Hoy")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(Date(), style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 16) {
                                    StatCard(
                                        symbol: "🍅",
                                        value: "\(viewModel.todayPomodoros)",
                                        label: String(localized: "Pomodoros"),
                                        color: .pomoPrimary
                                    )
                                    .frame(maxWidth: .infinity)
                                    
                                    StatCard(
                                        symbol: "⏱️",
                                        value: viewModel.todayTimeString,
                                        label: String(localized: "Tiempo total"),
                                        color: .pomoSecondary
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            
                            // GRÁFICA DE ESTADÍSTICAS
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Esta semana")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
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
                                        .fontWeight(.semibold)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.pomoPrimary, .pomoSecondary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
                .navigationTitle("Estadísticas")
                .navigationBarTitleDisplayMode(.large)
                .task {
                    viewModel.dataService.setModelContext(modelContext)
                    await viewModel.loadData()
                }
                .onAppear {
                    // Animación suave del gradiente
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        backgroundGradient = Gradient(colors: [
                            Color.pomoSecondary.opacity(0.4),
                            Color.pomoPrimary.opacity(0.3),
                            .purple.opacity(0.2)
                        ])
                    }
                }
            } else {
                // CÓDIGO ORIGINAL PARA iOS 18 Y ANTERIORES
                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.currentStreak > 0 {
                            HStack {
                                Text("🔥")
                                    .font(.system(size: 50))
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
                            .background(Color.pomoPrimary.opacity(0.1))
                            .cornerRadius(16)
                        }
                        
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
                            
                            HStack(spacing: 20) {
                                StatCard(
                                    symbol: "🍅",
                                    value: "\(viewModel.todayPomodoros)",
                                    label: String(localized: "Pomodoros"),
                                    color: .pomoPrimary
                                )
                                .frame(maxWidth: .infinity)
                                
                                StatCard(
                                    symbol: "⏱️",
                                    value: viewModel.todayTimeString,
                                    label: String(localized: "Tiempo total"),
                                    color: .pomoSecondary
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Esta semana")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if !viewModel.weeklyData.isEmpty {
                                WeeklyChart(data: viewModel.weeklyData)
                                    .frame(height: 200)
                            } else {
                                Text("No hay datos esta semana")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
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
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    .padding()
                }
                .navigationTitle("Estadísticas")
                .navigationBarTitleDisplayMode(.large)
                .refreshable {
                    await viewModel.loadData()
                }
                .task {
                    viewModel.dataService.setModelContext(modelContext)
                    await viewModel.loadData()
                }
                .onAppear {
                    Task {
                        await viewModel.loadData()
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let symbol: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        if #available(iOS 26, *) {
            VStack(spacing: 8) {
                Text(symbol)
                    .font(.system(size: 40))
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        } else {
            // CÓDIGO ORIGINAL
            VStack(spacing: 8) {
                Text(symbol)
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
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}
