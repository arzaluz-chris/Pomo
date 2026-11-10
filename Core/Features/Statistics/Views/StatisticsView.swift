// Core/Features/Statistics/Views/StatisticsView.swift

import SwiftUI
import SwiftData

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PomoSpace.l) {
                    today
                    week
                }
                .padding(.horizontal, PomoSpace.m)
                .padding(.bottom, PomoSpace.xl)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background { PomoScreenBackground(tint: PomoPalette.focus, intensity: 0.1) }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await viewModel.loadData() }
            .task {
                viewModel.dataService.setModelContext(modelContext)
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Today

    private var today: some View {
        VStack(alignment: .leading, spacing: PomoSpace.s) {
            PomoSectionHeader(title: String(localized: "Hoy"),
                              trailing: Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))

            HStack(spacing: PomoSpace.s) {
                PomoStatTile(value: "\(viewModel.todayPomodoros)",
                             label: String(localized: "Pomodoros"),
                             tint: PomoPalette.focus) {
                    PomoMark(showsDial: false)
                }

                PomoStatTile(value: viewModel.todayTimeString,
                             label: String(localized: "Tiempo total"),
                             tint: PomoPalette.shortBreak) {
                    Image(systemName: "clock.fill").font(.title2)
                }
            }

            streakCard
        }
    }

    private var streakCard: some View {
        HStack(spacing: PomoSpace.m) {
            Image(systemName: viewModel.currentStreak > 0 ? "flame.fill" : "flame")
                .font(.title2.weight(.semibold))
                .foregroundStyle(viewModel.currentStreak > 0 ? PomoPalette.focus : .secondary)
                .frame(width: 44, height: 44)
                .background((viewModel.currentStreak > 0 ? PomoPalette.focus : Color.secondary).opacity(0.12),
                            in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Racha actual")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(streakText)
                    .font(.pomoRounded(.title3, weight: .bold))
            }
            Spacer()
        }
        .pomoCard()
        .accessibilityElement(children: .combine)
    }

    private var streakText: String {
        let days = viewModel.currentStreak
        return "\(days) \(days == 1 ? String(localized: "día") : String(localized: "días"))"
    }

    // MARK: - Week

    private var week: some View {
        let total = viewModel.weeklyData.reduce(0) { $0 + $1.pomodoros }
        return VStack(alignment: .leading, spacing: PomoSpace.s) {
            PomoSectionHeader(title: String(localized: "Esta semana"),
                              trailing: "\(total) pomodoros")

            VStack(alignment: .leading, spacing: PomoSpace.m) {
                if total == 0 {
                    VStack(spacing: PomoSpace.s) {
                        PomoMark(tint: Color.secondary.opacity(0.25), leafTint: Color.secondary.opacity(0.35))
                            .frame(width: 56, height: 56)
                        Text("No hay datos esta semana")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    WeeklyChart(data: viewModel.weeklyData)
                        .frame(height: 200)
                }
            }
            .pomoCard()
        }
    }
}
