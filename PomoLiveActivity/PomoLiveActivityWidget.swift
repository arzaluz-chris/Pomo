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
                // Vista expandida
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: getIconForSessionType(context.attributes.sessionType))
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
                    HStack(spacing: 32) {
                        // Botón Pausar/Reanudar
                        Button(intent: TogglePauseIntent(
                            sessionType: context.attributes.sessionType,
                            isPaused: context.state.isPaused
                        )) {
                            Image(systemName: context.state.isPaused ? "play.fill" : "pause.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        
                        // Botón Reiniciar
                        Button(intent: ResetTimerIntent(
                            sessionType: context.attributes.sessionType
                        )) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                Image(systemName: getIconForSessionType(context.attributes.sessionType))
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
                Image(systemName: getIconForSessionType(context.attributes.sessionType))
                    .font(.caption)
                    .foregroundColor(Color("PomoPrimary"))
            }
            .widgetURL(URL(string: "pomo://timer"))
            .keylineTint(Color("PomoPrimary"))
        }
    }
    
    // Funciones helper
    private func getIconForSessionType(_ sessionType: String) -> String {
        switch sessionType {
        case "work":
            return "brain.fill"
        case "shortBreak", "longBreak":
            return "cup.and.saucer.fill"
        default:
            return "timer"
        }
    }
    
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
                    
                    Text("• \(String(localized: "Sesión")) #\(context.attributes.sessionNumber)")
                        .font(.caption)
                        .foregroundColor(Color("PomoSecondary"))
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
                
                // Barra de progreso
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Fondo
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("PomoSecondary").opacity(0.2))
                            .frame(height: 8)
                        
                        // Progreso
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("PomoPrimary"))
                            .frame(
                                width: geometry.size.width * progress,
                                height: 8
                            )
                    }
                }
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
    
    private var progress: Double {
        let elapsed = Double(context.attributes.totalDuration - context.state.timeRemaining)
        return elapsed / Double(context.attributes.totalDuration)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
