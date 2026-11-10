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
            .background { PomoPage() }
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
                PomoStatTile(value: "\(viewModel.todayPomodoros)", label: String(localized: "Pomodoros"), tint: PomoPalette.focus)
                PomoStatTile(value: viewModel.todayTimeString, label: String(localized: "Tiempo total"), tint: PomoPalette.shortBreak)
            }
            streakCard
        }
    }

    private var streakCard: some View {
        let active = viewModel.currentStreak > 0
        return HStack(spacing: PomoSpace.m) {
            Image(systemName: active ? "flame.fill" : "flame")
                .font(.title2.weight(.bold))
                .foregroundStyle(active ? PomoPalette.cream : PomoPalette.muted)
                .frame(width: 48, height: 48)
                .background(active ? PomoPalette.leaf : PomoPalette.chrome, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Racha actual")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PomoPalette.muted)
                Text(streakText)
                    .font(.pomoRounded(.title2, weight: .black))
                    .foregroundStyle(active ? PomoPalette.leaf : PomoPalette.inkText)
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
            PomoSectionHeader(title: String(localized: "Esta semana"), trailing: "\(total) pomodoros")
            Group {
                if total == 0 {
                    VStack(spacing: PomoSpace.s) {
                        PomoMark(tint: PomoPalette.hairline, leafTint: PomoPalette.chrome)
                            .frame(width: 56, height: 56)
                        Text("No hay datos esta semana")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PomoPalette.muted)
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
