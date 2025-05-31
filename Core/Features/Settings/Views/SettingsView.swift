// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Duración de las sesiones") {
                    DurationSlider(
                        title: String(localized: "Trabajo"),
                        value: $viewModel.workDuration,
                        range: 10...60
                    )
                    
                    DurationSlider(
                        title: String(localized: "Descanso corto"),
                        value: $viewModel.shortBreakDuration,
                        range: 3...15
                    )
                    
                    DurationSlider(
                        title: String(localized: "Descanso largo"),
                        value: $viewModel.longBreakDuration,
                        range: 10...30
                    )
                }
                
                Section("Configuración") {
                    Stepper(String(localized: "Sesiones hasta descanso largo: \(viewModel.sessionsUntilLongBreak)"),
                        value: $viewModel.sessionsUntilLongBreak,
                        in: 2...6
                    )
                    
                    Toggle("Notificaciones", isOn: $viewModel.isNotificationEnabled)
                    
                    Toggle("Sonido", isOn: $viewModel.isSoundEnabled)
                }
                
                Section {
                    Button("Restablecer valores predeterminados") {
                        viewModel.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
