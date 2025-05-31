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
    
    // Observar cambios en UserDefaults con property observers
    @AppStorage(Constants.UserDefaults.workDuration) private var workDurationSetting: Int = Constants.Defaults.workDuration / 60 {
        didSet {
            if !isActive && currentType == .work {
                timeRemaining = getDuration(for: .work)
            }
        }
    }
    @AppStorage(Constants.UserDefaults.shortBreakDuration) private var shortBreakDurationSetting: Int = Constants.Defaults.shortBreakDuration / 60 {
        didSet {
            if !isActive && currentType == .shortBreak {
                timeRemaining = getDuration(for: .shortBreak)
            }
        }
    }
    @AppStorage(Constants.UserDefaults.longBreakDuration) private var longBreakDurationSetting: Int = Constants.Defaults.longBreakDuration / 60 {
        didSet {
            if !isActive && currentType == .longBreak {
                timeRemaining = getDuration(for: .longBreak)
            }
        }
    }
    
    private var timer: Timer?
    private var startTime: Date?
    private var backgroundTime: Date?
    private let soundService = SoundService()
    private let notificationService = NotificationService()
    let dataService = DataService()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Haptic feedback generators
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    var progress: Double {
        let total = Double(getDuration(for: currentType))
        return total > 0 ? Double(timeRemaining) / total : 0
    }
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var buttonTitle: String {
        isActive ? "PAUSAR" : "INICIAR"
    }
    
    init() {
        // Preparar los generadores de haptic
        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()

        resetTimer()
        setupNotifications()
        setupSettingsObservers()
    }
    

    
    private func setupNotifications() {
        // Observar cuando la app entra en background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleEnterBackground()
            }
            .store(in: &cancellables)
        
        // Observar cuando la app vuelve a foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleEnterForeground()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupSettingsObservers() {
        // Observar cambios en UserDefaults directamente
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self = self, !self.isActive else { return }

                    // Actualizar el tiempo si no está activo el timer
                    let newDuration = self.getDuration(for: self.currentType)
                    if self.timeRemaining != newDuration {
                        self.timeRemaining = newDuration
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleEnterBackground() {
        if isActive {
            backgroundTime = Date()
            scheduleBackgroundNotification()
        }
    }
    
    private func handleEnterForeground() {
        guard isActive, let backgroundTime = backgroundTime else { return }
        
        // Calcular cuánto tiempo pasó
        let elapsed = Int(Date().timeIntervalSince(backgroundTime))
        
        // Actualizar el tiempo restante
        timeRemaining = max(0, timeRemaining - elapsed)
        
        // Si el tiempo se acabó mientras estaba en background
        if timeRemaining == 0 {
            completeSession(wasCompleted: true)
        }
        
        self.backgroundTime = nil
        
        // Cancelar notificaciones pendientes ya que la app está activa
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleBackgroundNotification() {
        guard timeRemaining > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "¡Tiempo completado!"
        
        // Usar sonido personalizado si está habilitado
        if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(currentType.soundFileName).mp3"))
        } else {
            content.sound = .default
        }
        
        switch currentType {
        case .work:
            content.body = "Has completado una sesión de trabajo. ¡Toma un descanso!"
        case .shortBreak:
            content.body = "El descanso ha terminado. ¡Es hora de trabajar!"
        case .longBreak:
            content.body = "El descanso largo ha terminado. ¡Vamos a por otra ronda!"
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timeRemaining), repeats: false)
        let request = UNNotificationRequest(identifier: "timerComplete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func toggleTimer() {
        // Haptic feedback para play/pause
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        if isActive {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func resetTimer() {
        // Haptic feedback para reset
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
        
        pauseTimer()
        timeRemaining = getDuration(for: currentType)
        startTime = nil
        backgroundTime = nil
    }
    
    func skipSession() {
        // Haptic feedback ligero para skip
        let lightImpact = UIImpactFeedbackGenerator(style: .light)
        lightImpact.prepare()
        lightImpact.impactOccurred()
        
        completeSession(wasCompleted: false)
    }
    
    func changeTimerType(to type: TimerType) {
        guard !isActive && currentType != type else { return }
        
        // Haptic feedback para cambio de tipo
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
        
        currentType = type
        resetTimer()
    }
    
    private func startTimer() {
        isActive = true
        startTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.completeSession(wasCompleted: true)
                }
            }
        }
    }
    
    private func pauseTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
        backgroundTime = nil
        
        // Cancelar notificaciones si se pausa el timer
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func completeSession(wasCompleted: Bool) {
        pauseTimer()
        
        // Haptic feedback para sesión completada
        if wasCompleted {
            // Patrón de vibración personalizado para completar
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.success)
            
            // Vibración adicional más fuerte
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
                heavyImpact.prepare()
                heavyImpact.impactOccurred()
            }
        } else {
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.warning)
        }
        
        // Guardar sesión - AQUÍ ESTÁ LA CORRECCIÓN
        if let startTime = startTime {
            let totalDuration = getDuration(for: currentType)
            let elapsedTime = totalDuration - timeRemaining
            
            // Debug para verificar los valores
            print("DEBUG - Guardando sesión:")
            print("  Tipo: \(currentType)")
            print("  Duración total: \(totalDuration) segundos")
            print("  Tiempo restante: \(timeRemaining) segundos")
            print("  Tiempo transcurrido: \(elapsedTime) segundos")
            print("  Completada: \(wasCompleted)")
            
            Task {
                await dataService.saveSession(
                    startDate: startTime,
                    endDate: Date(),
                    duration: elapsedTime, // Tiempo real transcurrido
                    type: currentType,
                    wasCompleted: wasCompleted
                )
            }
        }
        
        if wasCompleted {
            // Reproducir sonido
            if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
                soundService.playSound(for: currentType)
            }
            
            // Enviar notificación solo si la app está en background
            if UIApplication.shared.applicationState != .active {
                Task {
                    await notificationService.scheduleSessionComplete(type: currentType)
                }
            }
            
            // Actualizar contador de sesiones
            if currentType == .work {
                completedSessions += 1
            }
        }
        
        // Cambiar al siguiente tipo
        switchToNextType()
        resetTimer()
    }
    
    private func switchToNextType() {
        switch currentType {
        case .work:
            let sessionsUntilLong = UserDefaults.standard.integer(forKey: Constants.UserDefaults.sessionsUntilLongBreak)
            if completedSessions > 0 && completedSessions % sessionsUntilLong == 0 {
                currentType = .longBreak
            } else {
                currentType = .shortBreak
            }
        case .shortBreak, .longBreak:
            currentType = .work
        }
    }
    
    private func getDuration(for type: TimerType) -> Int {
        let minutes: Int
        switch type {
        case .work:
            minutes = UserDefaults.standard.integer(forKey: Constants.UserDefaults.workDuration)
            return minutes > 0 ? minutes * 60 : Constants.Defaults.workDuration
        case .shortBreak:
            minutes = UserDefaults.standard.integer(forKey: Constants.UserDefaults.shortBreakDuration)
            return minutes > 0 ? minutes * 60 : Constants.Defaults.shortBreakDuration
        case .longBreak:
            minutes = UserDefaults.standard.integer(forKey: Constants.UserDefaults.longBreakDuration)
            return minutes > 0 ? minutes * 60 : Constants.Defaults.longBreakDuration
        }
    }
}
