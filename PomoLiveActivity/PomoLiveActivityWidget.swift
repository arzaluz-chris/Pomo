// PomoLiveActivityWidget.swift
// Ubicación: PomoLiveActivity/PomoLiveActivityWidget.swift

import ActivityKit
import WidgetKit
import SwiftUI

struct PomoLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomoActivityAttributes.self) { context in
            // Vista para el Lock Screen
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color("PomoBackground"))
                .activitySystemActionForegroundColor(Color("PomoPrimary"))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Vista expandida con mejor espaciado
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: context.attributes.sessionType == "work" ? "brain.fill" : "cup.and.saucer.fill")
                            .font(.title2)
                            .foregroundColor(Color("PomoPrimary"))
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(getDisplayNameForSessionType(context.attributes.sessionType))
                        .font(.caption)
                        .foregroundColor(Color("PomoSecondary"))
                }
                
                DynamicIslandExpandedRegion(.center) {
                    if context.state.isPaused {
                        Text(formatTime(context.state.timeRemaining))
                            .font(.title2.monospacedDigit())
                            .foregroundColor(Color("PomoPrimary"))
                    } else {
                        Text(timerInterval: Date.now...context.state.endTime)
                            .font(.title2.monospacedDigit())
                            .foregroundColor(Color("PomoPrimary"))
                            .frame(width: 90)
                            .multilineTextAlignment(.center)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Mejor espaciado entre botones
                    HStack {
                        // Botón Pausar/Reanudar alineado a la izquierda
                        Button(intent: TogglePauseIntent(
                            sessionType: context.attributes.sessionType,
                            isPaused: context.state.isPaused
                        )) {
                            Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Botón Reiniciar alineado a la derecha
                        Button(intent: ResetTimerIntent(
                            sessionType: context.attributes.sessionType
                        )) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                }
            } compactLeading: {
                Image(systemName: context.attributes.sessionType == "work" ? "brain.fill" : "cup.and.saucer.fill")
                    .font(.caption)
                    .foregroundColor(Color("PomoPrimary"))
            } compactTrailing: {
                if context.state.isPaused {
                    Text(formatTimeCompact(context.state.timeRemaining))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(Color("PomoPrimary"))
                } else {
                    Text(timerInterval: Date.now...context.state.endTime)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(Color("PomoPrimary"))
                        .frame(width: 40)
                }
            } minimal: {
                Image(systemName: context.attributes.sessionType == "work" ? "brain.fill" : "cup.and.saucer.fill")
                    .font(.caption)
                    .foregroundColor(Color("PomoPrimary"))
            }
            .widgetURL(URL(string: "pomo://timer"))
            .keylineTint(Color("PomoPrimary"))
        }
    }
    
    // Funciones helper
    private func getDisplayNameForSessionType(_ sessionType: String) -> String {
        switch sessionType {
        case "work":
            return String(localized: "Trabajo")
        case "shortBreak":
            return String(localized: "Descanso")
        case "longBreak":
            return String(localized: "Descanso Largo")
        default:
            return ""
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func formatTimeCompact(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        } else {
            return String(format: "%ds", remainingSeconds)
        }
    }
}

// Vista para el Lock Screen
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PomoActivityAttributes>
    
    var body: some View {
        HStack {
            // Icono
            Image(systemName: iconName)
                .font(.largeTitle)
                .foregroundColor(Color("PomoPrimary"))
            
            VStack(alignment: .leading, spacing: 4) {
                // Tipo de sesión
                HStack {
                    Text(sessionDisplayName)
                        .font(.headline)
                        .foregroundColor(Color("PomoPrimary"))
                    
                    if context.attributes.sessionNumber > 0 {
                        Text("• \(String(localized: "Sesión")) #\(context.attributes.sessionNumber)")
                            .font(.caption)
                            .foregroundColor(Color("PomoSecondary"))
                    }
                }
                
                // Temporizador
                HStack {
                    if context.state.isPaused {
                        Image(systemName: "pause.fill")
                            .font(.caption)
                            .foregroundColor(Color("PomoSecondary"))
                        
                        Text(formatTime(context.state.timeRemaining))
                            .font(.title2.monospacedDigit().bold())
                            .foregroundColor(Color("PomoPrimary"))
                    } else {
                        Text(timerInterval: Date.now...context.state.endTime)
                            .font(.title2.monospacedDigit().bold())
                            .foregroundColor(Color("PomoPrimary"))
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Barra de progreso con actualización en tiempo real
                ProgressBarView(
                    totalDuration: context.attributes.totalDuration,
                    timeRemaining: context.state.timeRemaining,
                    isPaused: context.state.isPaused,
                    endTime: context.state.endTime,
                    startTime: context.state.startTime
                )
                .frame(height: 8)
            }
            
            Spacer()
            
            // Botones
            VStack(spacing: 8) {
                Button(intent: TogglePauseIntent(
                    sessionType: context.attributes.sessionType,
                    isPaused: context.state.isPaused
                )) {
                    Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                        .font(.title3)
                        .foregroundColor(Color("PomoPrimary"))
                        .frame(width: 44, height: 44)
                        .background(Color("PomoSecondary").opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button(intent: ResetTimerIntent(
                    sessionType: context.attributes.sessionType
                )) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(Color("PomoSecondary"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
    
    private var iconName: String {
        switch context.attributes.sessionType {
        case "work":
            return "brain.fill"
        case "shortBreak", "longBreak":
            return "cup.and.saucer.fill"
        default:
            return "timer"
        }
    }
    
    private var sessionDisplayName: String {
        switch context.attributes.sessionType {
        case "work":
            return String(localized: "Trabajo")
        case "shortBreak":
            return String(localized: "Descanso")
        case "longBreak":
            return String(localized: "Descanso Largo")
        default:
            return ""
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// Vista separada para la barra de progreso que se actualiza en tiempo real
struct ProgressBarView: View {
    let totalDuration: Int
    let timeRemaining: Int
    let isPaused: Bool
    let endTime: Date
    let startTime: Date
    
    @State private var currentProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Fondo
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("PomoSecondary").opacity(0.2))
                
                // Progreso
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("PomoPrimary"))
                    .frame(width: geometry.size.width * currentProgress)
                    .animation(.linear(duration: 0.3), value: currentProgress)
            }
        }
        .onAppear {
            updateProgress()
            if !isPaused {
                startProgressTimer()
            }
        }
        .onChange(of: isPaused) { _, newValue in
            if !newValue {
                startProgressTimer()
            }
        }
    }
    
    private func updateProgress() {
        if isPaused {
            // Si está pausado, calcular progreso basado en tiempo restante
            let elapsed = Double(totalDuration - timeRemaining)
            currentProgress = max(0, min(1, elapsed / Double(totalDuration)))
        } else {
            // Si está activo, calcular progreso basado en tiempo real
            let now = Date()
            let totalInterval = endTime.timeIntervalSince(startTime)
            let elapsedInterval = now.timeIntervalSince(startTime)
            currentProgress = max(0, min(1, elapsedInterval / totalInterval))
        }
    }
    
    private func startProgressTimer() {
        // Actualizar cada segundo si no está pausado
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if isPaused {
                timer.invalidate()
            } else {
                updateProgress()
            }
        }
    }
}
