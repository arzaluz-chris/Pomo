// Core/Features/Settings/Views/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var timerViewModel: TimerViewModel
    @State private var showResetAlert = false
    @State private var alarmPermissionDenied = false
    private let reviewService = ReviewService.shared

    var body: some View {
        NavigationStack {
            PomoFoldPanes {
                durations
                cycle
            } trailing: {
                alerts
                about
            }
            .background { PomoPage() }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
            .alert("¿Restablecer ajustes?", isPresented: $showResetAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Restablecer", role: .destructive) {
                    viewModel.resetToDefaults()
                    timerViewModel.alertPreferenceChanged()
                }
            } message: {
                Text("Esto restablecerá todos los ajustes a sus valores predeterminados.")
            }
            .alert(String(localized: "Alarms are turned off for Pomo", comment: "Alert title"),
                   isPresented: $alarmPermissionDenied) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(String(localized: "Allow alarms for Pomo in Settings to use alarm-style alerts.", comment: "Alert message"))
            }
        }
    }

    // MARK: - Sections

    private var durations: some View {
        VStack(alignment: .leading, spacing: PomoSpace.s) {
            PomoSectionHeader(title: String(localized: "Duración de las sesiones"))
            VStack(spacing: PomoSpace.m) {
                PomoSliderRow(title: TimerType.work.displayName, systemImage: TimerType.work.symbolName,
                              tint: TimerType.work.tint, value: $viewModel.workDuration, range: TimerType.work.adjustableMinutes)
                PomoDivider()
                PomoSliderRow(title: TimerType.shortBreak.displayName, systemImage: TimerType.shortBreak.symbolName,
                              tint: TimerType.shortBreak.tint, value: $viewModel.shortBreakDuration, range: TimerType.shortBreak.adjustableMinutes)
                PomoDivider()
                PomoSliderRow(title: TimerType.longBreak.displayName, systemImage: TimerType.longBreak.symbolName,
                              tint: TimerType.longBreak.tint, value: $viewModel.longBreakDuration, range: TimerType.longBreak.adjustableMinutes)
            }
            .pomoCard()
        }
    }

    private var cycle: some View {
        VStack(alignment: .leading, spacing: PomoSpace.s) {
            PomoSectionHeader(title: String(localized: "Configuración"))
            VStack(alignment: .leading, spacing: PomoSpace.s) {
                PomoSliderRow(title: String(localized: "Sesiones para descanso largo"),
                              systemImage: "repeat", tint: PomoPalette.longBreak,
                              value: $viewModel.sessionsUntilLongBreak, range: 2...6, unit: nil)
                CyclePreview(sessions: viewModel.sessionsUntilLongBreak)
                    .padding(.leading, 42)
            }
            .pomoCard()
        }
    }

    private var alerts: some View {
        VStack(alignment: .leading, spacing: PomoSpace.s) {
            PomoSectionHeader(title: String(localized: "Alerts", comment: "Settings section"))
            VStack(spacing: PomoSpace.xs) {
                PomoToggleRow(title: String(localized: "Notificaciones"),
                              subtitle: String(localized: "Alertas al completar sesiones"),
                              systemImage: "bell.badge.fill", tint: PomoPalette.focus,
                              isOn: $viewModel.isNotificationEnabled)
                PomoDivider()
                PomoToggleRow(title: String(localized: "Sonido"),
                              subtitle: String(localized: "Efectos de sonido"),
                              systemImage: "speaker.wave.2.fill", tint: PomoPalette.shortBreak,
                              isOn: $viewModel.isSoundEnabled)
                if #available(iOS 26, *) {
                    PomoDivider()
                    PomoToggleRow(title: String(localized: "Alarm-style alert", comment: "Settings toggle"),
                                  subtitle: String(localized: "Rings even in silent mode or during a Focus.", comment: "Settings toggle subtitle"),
                                  systemImage: "alarm.fill", tint: PomoPalette.leaf,
                                  isOn: alarmBinding)
                }
            }
            .pomoCard()
            .onChange(of: viewModel.isNotificationEnabled) { timerViewModel.alertPreferenceChanged() }
        }
    }

    private var about: some View {
        VStack(spacing: PomoSpace.xs) {
            Button {
                reviewService.openAppStoreForReview()
            } label: {
                HStack(spacing: PomoSpace.s) {
                    PomoIconBadge(systemImage: "star.fill", tint: PomoPalette.focus)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calificar en App Store")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(PomoPalette.inkText)
                        Text("Ayúdanos con una reseña")
                            .font(.footnote)
                            .foregroundStyle(PomoPalette.muted)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(PomoPalette.muted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            PomoDivider()

            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                HStack(spacing: PomoSpace.s) {
                    PomoIconBadge(systemImage: "arrow.counterclockwise", tint: PomoPalette.focus)
                    Text("Restablecer valores predeterminados")
                        .font(.body.weight(.semibold))
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(PomoPalette.focus)
        }
        .pomoCard()
    }

    // MARK: - Alarm permission

    private var alarmBinding: Binding<Bool> {
        Binding {
            viewModel.useAlarmAlerts
        } set: { enabled in
            guard enabled else {
                viewModel.useAlarmAlerts = false
                timerViewModel.alertPreferenceChanged()
                return
            }
            guard #available(iOS 26, *) else { return }
            Task {
                let granted = await PomoAlarmService.shared.requestAuthorization()
                viewModel.useAlarmAlerts = granted
                alarmPermissionDenied = !granted
                timerViewModel.alertPreferenceChanged()
            }
        }
    }
}

/// Dots showing the focus sessions before each long break.
private struct CyclePreview: View {
    let sessions: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<sessions, id: \.self) { _ in
                Capsule().fill(PomoPalette.focus).frame(width: 18, height: 8)
                Capsule().fill(PomoPalette.shortBreak).frame(width: 8, height: 8)
            }
            Capsule().fill(PomoPalette.longBreak).frame(width: 26, height: 8)
        }
        .accessibilityHidden(true)
    }
}
