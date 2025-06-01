// TimerViewModel.swift

import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
class TimerViewModel: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var isActive: Bool = false
    @Published var currentType: TimerType = .work
    @Published var completedSessions: Int = 0
    
    // Configuraciones de duración
    @AppStorage(Constants.UserDefaults.workDuration) private var workDurationMinutes: Int = Constants.Defaults.workDuration / 60
    @AppStorage(Constants.UserDefaults.shortBreakDuration) private var shortBreakDurationMinutes: Int = Constants.Defaults.shortBreakDuration / 60
    @AppStorage(Constants.UserDefaults.longBreakDuration) private var longBreakDurationMinutes: Int = Constants.Defaults.longBreakDuration / 60
    @AppStorage(Constants.UserDefaults.sessionsUntilLongBreak) private var sessionsUntilLongBreak: Int = Constants.Defaults.sessionsUntilLongBreak
    
    // Estado persistente del timer
    @AppStorage("savedTimerEndTime") private var savedEndTime: Double = 0
    @AppStorage("savedTimerIsActive") private var savedIsActive: Bool = false
    @AppStorage("savedTimerType") private var savedTimerType: String = TimerType.work.rawValue
    @AppStorage("savedCompletedSessions") private var savedCompletedSessions: Int = 0
    
    private var timer: Timer?
    private var sessionStartTime: Date?
    private let soundService = SoundService()
    private let notificationService = NotificationService()
    let dataService = DataService()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Haptic feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    var progress: Double {
        let total = Double(getDurationForType(currentType))
        return total > 0 ? Double(timeRemaining) / total : 0
    }
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var buttonTitle: String {
        isActive ? String(localized: "PAUSAR") : String(localized: "INICIAR")
    }
    
    init() {
        setupHaptics()
        restoreState()
        setupNotificationObservers()
        
        // Limpiar notificaciones al iniciar
        notificationService.cancelAllNotifications()
    }
    
    private func setupHaptics() {
        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    private func restoreState() {
        // Restaurar sesiones completadas
        completedSessions = savedCompletedSessions
        
        // Restaurar tipo de timer
        if let type = TimerType(rawValue: savedTimerType) {
            currentType = type
        }
        
        // Verificar si hay un timer activo
        if savedIsActive && savedEndTime > Date().timeIntervalSince1970 {
            // Calcular tiempo restante
            let remaining = Int(savedEndTime - Date().timeIntervalSince1970)
            if remaining > 0 {
                timeRemaining = remaining
                isActive = true
                startTimerCounting()
            } else {
                // El timer expiró mientras la app estaba cerrada
                handleTimerExpired()
            }
        } else {
            // No hay timer activo
            resetToInitialState()
        }
    }
    
    private func setupNotificationObservers() {
        // App yendo a background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppGoingToBackground()
            }
            .store(in: &cancellables)
        
        // App volviendo a foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleAppComingToForeground()
                }
            }
            .store(in: &cancellables)
        
        // Observar cambios en configuraciones
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleSettingsChange()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleAppGoingToBackground() {
        guard isActive else { return }
        
        // Guardar estado
        savedEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
        savedIsActive = true
        savedTimerType = currentType.rawValue
        savedCompletedSessions = completedSessions
        
        // Programar UNA SOLA notificación
        Task {
            await notificationService.scheduleTimerCompletionNotification(
                for: currentType,
                in: TimeInterval(timeRemaining)
            )
        }
    }
    
    private func handleAppComingToForeground() {
        // Cancelar notificaciones pendientes
        notificationService.cancelAllNotifications()
        
        guard savedIsActive else { return }
        
        let now = Date().timeIntervalSince1970
        
        if savedEndTime > now {
            // Timer aún activo
            timeRemaining = Int(savedEndTime - now)
            if !isActive {
                isActive = true
                startTimerCounting()
            }
        } else {
            // Timer expiró
            handleTimerExpired()
        }
    }
    
    private func handleSettingsChange() {
        guard !isActive else { return }
        
        // Actualizar duración si cambió la configuración
        timeRemaining = getDurationForType(currentType)
    }
    
    private func handleTimerExpired() {
        timeRemaining = 0
        sessionCompleted(wasSkipped: false)
    }
    
    // MARK: - Acciones públicas
    
    func toggleTimer() {
        impactFeedback.impactOccurred()
        
        if isActive {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func resetTimer() {
        selectionFeedback.selectionChanged()
        
        pauseTimer()
        resetToInitialState()
    }
    
    func skipSession() {
        guard isActive else { return }
        
        let lightImpact = UIImpactFeedbackGenerator(style: .light)
        lightImpact.impactOccurred()
        
        sessionCompleted(wasSkipped: true)
    }
    
    func changeTimerType(to type: TimerType) {
        guard !isActive && type != currentType else { return }
        
        selectionFeedback.selectionChanged()
        
        currentType = type
        savedTimerType = type.rawValue
        timeRemaining = getDurationForType(type)
    }
    
    // MARK: - Timer Control
    
    private func startTimer() {
        isActive = true
        savedIsActive = true
        sessionStartTime = Date()
        savedEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
        
        startTimerCounting()
    }
    
    private func startTimerCounting() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateTimer()
            }
        }
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            sessionCompleted(wasSkipped: false)
        }
    }
    
    private func pauseTimer() {
        isActive = false
        savedIsActive = false
        savedEndTime = 0
        timer?.invalidate()
        timer = nil
        
        notificationService.cancelAllNotifications()
    }
    
    private func resetToInitialState() {
        timeRemaining = getDurationForType(currentType)
        sessionStartTime = nil
        savedEndTime = 0
        savedIsActive = false
    }
    
    // MARK: - Session Completion
    
    private func sessionCompleted(wasSkipped: Bool) {
        // Detener timer
        timer?.invalidate()
        timer = nil
        isActive = false
        savedIsActive = false
        
        // Haptic feedback
        if !wasSkipped {
            notificationFeedback.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
                heavyImpact.impactOccurred()
            }
        } else {
            notificationFeedback.notificationOccurred(.warning)
        }
        
        // Guardar datos de la sesión
        if let startTime = sessionStartTime {
            let duration = getDurationForType(currentType) - timeRemaining
            
            Task {
                await dataService.saveSession(
                    startDate: startTime,
                    endDate: Date(),
                    duration: duration,
                    type: currentType,
                    wasCompleted: !wasSkipped
                )
            }
        }
        
        // Reproducir sonido solo si la app está activa y la sesión se completó
        if !wasSkipped && UIApplication.shared.applicationState == .active {
            if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
                soundService.playSound(for: currentType)
            }
        }
        
        // Incrementar contador si fue una sesión de trabajo completada
        if currentType == .work && !wasSkipped {
            completedSessions += 1
            savedCompletedSessions = completedSessions
        }
        
        // Cambiar al siguiente tipo de sesión
        moveToNextSessionType()
        
        // Resetear timer
        resetToInitialState()
    }
    
    private func moveToNextSessionType() {
        switch currentType {
        case .work:
            // Después del trabajo, verificar si toca descanso largo
            if completedSessions > 0 && completedSessions % sessionsUntilLongBreak == 0 {
                currentType = .longBreak
            } else {
                currentType = .shortBreak
            }
        case .shortBreak, .longBreak:
            // Después de cualquier descanso, volver al trabajo
            currentType = .work
        }
        
        savedTimerType = currentType.rawValue
    }
    
    // MARK: - Helpers
    
    private func getDurationForType(_ type: TimerType) -> Int {
        switch type {
        case .work:
            return workDurationMinutes * 60
        case .shortBreak:
            return shortBreakDurationMinutes * 60
        case .longBreak:
            return longBreakDurationMinutes * 60
        }
    }
}
