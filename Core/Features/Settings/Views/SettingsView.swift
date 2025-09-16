// Core/Features/Settings/Views/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            if #available(iOS 26, *) {
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
                        // --- CAMBIO: Se usan símbolos de hoja en lugar de emojis ---
                        Stepper {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sesiones para descanso largo")
                                    .font(.headline)
                                
                                HStack {
                                    ForEach(1...viewModel.sessionsUntilLongBreak, id: \.self) { _ in
                                        Image(systemName: "leaf.fill") // Símbolo de hoja
                                            .foregroundStyle(.pomoSecondary) // Color verde de la app
                                            .transition(.scale)
                                    }
                                }
                                .animation(.bouncy, value: viewModel.sessionsUntilLongBreak)
                            }
                        } onIncrement: {
                            if viewModel.sessionsUntilLongBreak < 6 {
                                viewModel.sessionsUntilLongBreak += 1
                            }
                        } onDecrement: {
                            if viewModel.sessionsUntilLongBreak > 2 {
                                viewModel.sessionsUntilLongBreak -= 1
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Toggle(isOn: $viewModel.isNotificationEnabled) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                Text("Notificaciones")
                            }
                        }
                        
                        Toggle(isOn: $viewModel.isSoundEnabled) {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                Text("Sonido")
                            }
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            viewModel.resetToDefaults()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                Text("Restablecer valores predeterminados")
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .navigationTitle("Ajustes")
            } else {
                // CÓDIGO ORIGINAL PARA iOS 18 Y ANTERIORES
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
}
