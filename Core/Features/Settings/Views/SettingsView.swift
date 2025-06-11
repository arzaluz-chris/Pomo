// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingTimeSensitiveInfo = false
    
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
                    
                    // Toggle de notificaciones con información adicional
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Notificaciones", isOn: $viewModel.isNotificationEnabled)
                        
                        if viewModel.isNotificationEnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("Time Sensitive habilitado")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button {
                                    showingTimeSensitiveInfo = true
                                } label: {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.leading, 2)
                        }
                    }
                    
                    Toggle("Sonido", isOn: $viewModel.isSoundEnabled)
                }
                
                Section {
                    Button("Restablecer valores predeterminados") {
                        viewModel.resetToDefaults()
                    }
                    .foregroundColor(.red)
                } footer: {
                    Text("Version 1.2.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
            .alert("Notificaciones Time Sensitive", isPresented: $showingTimeSensitiveInfo) {
                Button("Entendido", role: .cancel) { }
            } message: {
                Text("Las notificaciones Time Sensitive te alertarán cuando tus sesiones terminen, incluso si tu iPhone está en modo No Molestar o Enfoque. Esto asegura que no pierdas el ritmo de productividad.")
            }
        }
    }
}

#Preview {
    SettingsView()
}
