// Core/Features/Settings/Views/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var backgroundGradient = Gradient(colors: [Color.pomoPrimary.opacity(0.3), Color.pomoSecondary.opacity(0.4), .blue.opacity(0.3)])
    @State private var showResetAlert = false
    
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
                        VStack(spacing: 20) {
                            // SECCIÓN DURACIÓN DE SESIONES
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.pomoPrimary, .pomoSecondary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("Duración de las sesiones")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .padding(.bottom, 8)
                                
                                DurationSliderGlass(
                                    title: String(localized: "Trabajo"),
                                    value: $viewModel.workDuration,
                                    range: 10...60,
                                    icon: "laptopcomputer"
                                )
                                
                                DurationSliderGlass(
                                    title: String(localized: "Descanso corto"),
                                    value: $viewModel.shortBreakDuration,
                                    range: 3...15,
                                    icon: "cup.and.saucer.fill"
                                )
                                
                                DurationSliderGlass(
                                    title: String(localized: "Descanso largo"),
                                    value: $viewModel.longBreakDuration,
                                    range: 10...30,
                                    icon: "moon.fill"
                                )
                            }
                            .padding(24)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            
                            // SECCIÓN CONFIGURACIÓN
                            VStack(spacing: 20) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.pomoPrimary, .pomoSecondary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("Configuración")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                
                                // Sesiones para descanso largo con visualización mejorada
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Sesiones para descanso largo")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        ForEach(1...viewModel.sessionsUntilLongBreak, id: \.self) { index in
                                            Image(systemName: "leaf.fill")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [.pomoSecondary, .green],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .scaleEffect(index == viewModel.sessionsUntilLongBreak ? 1.2 : 1.0)
                                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.sessionsUntilLongBreak)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                if viewModel.sessionsUntilLongBreak > 2 {
                                                    withAnimation(.spring()) {
                                                        viewModel.sessionsUntilLongBreak -= 1
                                                    }
                                                }
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(viewModel.sessionsUntilLongBreak > 2 ? Color.pomoPrimary : Color.gray)
                                            }
                                            .disabled(viewModel.sessionsUntilLongBreak <= 2)
                                            
                                            Text("\(viewModel.sessionsUntilLongBreak)")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .frame(width: 30)
                                                .foregroundColor(.primary)
                                            
                                            Button(action: {
                                                if viewModel.sessionsUntilLongBreak < 6 {
                                                    withAnimation(.spring()) {
                                                        viewModel.sessionsUntilLongBreak += 1
                                                    }
                                                }
                                            }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(viewModel.sessionsUntilLongBreak < 6 ? Color.pomoPrimary : Color.gray)
                                            }
                                            .disabled(viewModel.sessionsUntilLongBreak >= 6)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                // Toggle de Notificaciones
                                Toggle(isOn: $viewModel.isNotificationEnabled) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "bell.badge.fill")
                                            .font(.title3)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: viewModel.isNotificationEnabled ? [.pomoPrimary, .purple] : [.gray],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Notificaciones")
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Text("Alertas al completar sesiones")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .tint(.pomoPrimary)
                                
                                // Toggle de Sonido
                                Toggle(isOn: $viewModel.isSoundEnabled) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.title3)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: viewModel.isSoundEnabled ? [.pomoSecondary, .green] : [.gray],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Sonido")
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Text("Efectos de sonido")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .tint(.pomoSecondary)
                            }
                            .padding(24)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            
                            // BOTÓN DE RESET
                            Button(action: {
                                showResetAlert = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.title3)
                                    Text("Restablecer valores predeterminados")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.red.opacity(0.8), .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .red.opacity(0.3), radius: 10, y: 5)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
                .navigationTitle("Ajustes")
                .navigationBarTitleDisplayMode(.large)
                .alert("¿Restablecer ajustes?", isPresented: $showResetAlert) {
                    Button("Cancelar", role: .cancel) { }
                    Button("Restablecer", role: .destructive) {
                        withAnimation(.spring()) {
                            viewModel.resetToDefaults()
                        }
                    }
                } message: {
                    Text("Esto restablecerá todos los ajustes a sus valores predeterminados.")
                }
                .onAppear {
                    // Animación suave del gradiente
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        backgroundGradient = Gradient(colors: [
                            Color.purple.opacity(0.2),
                            Color.pomoSecondary.opacity(0.4),
                            Color.pomoPrimary.opacity(0.3)
                        ])
                    }
                }
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

// Nuevo componente para sliders con efecto glass
struct DurationSliderGlass: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pomoPrimary, .pomoSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(value) min")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pomoPrimary, .pomoSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1) {
                Text(title)
            } minimumValueLabel: {
                Text("\(range.lowerBound)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } maximumValueLabel: {
                Text("\(range.upperBound)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .tint(
                LinearGradient(
                    colors: [.pomoPrimary, .pomoSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .padding(.vertical, 8)
    }
}
