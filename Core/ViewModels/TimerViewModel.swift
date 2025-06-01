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
    @AppStorage(Constants.UserDefaults.sessionsUntilLongBreak) private var sessionsUntilLongBreakSetting: Int = Constants.Defaults.sessionsUntilLongBreak
    
    // Nuevas propiedades para manejar el estado persistente
    @AppStorage("timerEndTime") private var timerEndTime: Double = 0
    @AppStorage("timerIsActive") private var timerIsActive: Bool = false
    @AppStorage("timerType") private var timerTypeRaw: String = TimerType.work.rawValue
    @AppStorage("completedWorkSessions") private var persistedCompletedSessions: Int = 0
    
    private var timer: Timer?
    private var startTime: Date?
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
        isActive ? String(localized: "PAUSAR") : String(localized: "INICIAR")
    }
    
    init() {
        // Preparar los generadores de haptic
        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
        
        // Cargar el estado persistido
        completedSessions = persistedCompletedSessions
        if let savedType = TimerType(rawValue: timerTypeRaw) {
            currentType = savedType
        }
        
        // IMPORTANTE: Limpiar todas las notificaciones al iniciar
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Verificar si hay un timer activo guardado
        if timerIsActive && timerEndTime > Date().timeIntervalSince1970 {
            // Restaurar el timer activo
            isActive = true
            timeRemaining = Int(timerEndTime - Date().timeIntervalSince1970)
            if timeRemaining > 0 {
                startTimer(isRestoring: true)
            } else {
                // El timer expiró mientras la app estaba cerrada
                timeRemaining = 0
                DispatchQueue.main.async { [weak self] in
                    self?.completeSession(wasCompleted: true)
                }
            }
        } else {
            // No hay timer activo, resetear
            timerIsActive = false
            timerEndTime = 0
            resetTimer()
        }
        
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
        
        // Observar cuando la app se va a terminar
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.handleAppTermination()
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
        // LIMPIAR notificaciones existentes
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        if isActive {
            // Guardar el estado
            timerEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
            timerIsActive = true
            timerTypeRaw = currentType.rawValue
            persistedCompletedSessions = completedSessions
            
            // Programar UNA SOLA notificación para cuando termine el timer
            if timeRemaining > 0 {
                Task {
                    await notificationService.scheduleFutureNotification(
                        type: currentType,
                        timeInterval: TimeInterval(timeRemaining)
                    )
                }
            }
        }
    }
    
    private func handleEnterForeground() {
        // LIMPIAR todas las notificaciones
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        guard timerIsActive, timerEndTime > 0 else { return }
        
        let now = Date().timeIntervalSince1970
        
        if timerEndTime > now {
            // El timer aún no ha terminado
            timeRemaining = Int(timerEndTime - now)
            if !isActive {
                isActive = true
                startTimer(isRestoring: true)
            }
        } else {
            // El timer terminó mientras estaba en background
            timeRemaining = 0
            completeSession(wasCompleted: true)
        }
    }
    
    private func handleAppTermination() {
        if isActive {
            // Asegurar que el estado se guarde cuando la app se cierra
            timerEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
            timerIsActive = true
            timerTypeRaw = currentType.rawValue
            persistedCompletedSessions = completedSessions
        }
    }
    
    func toggleTimer() {
        // Haptic feedback para play/pause
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        if isActive {
            pauseTimer()
        } else {
            startTimer(isRestoring: false)
        }
    }
    
    func resetTimer() {
        // Haptic feedback para reset
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
        
        pauseTimer()
        timeRemaining = getDuration(for: currentType)
        startTime = nil
        timerEndTime = 0
        timerIsActive = false
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
        timerTypeRaw = type.rawValue
        timeRemaining = getDuration(for: type)
    }
    
    private func startTimer(isRestoring: Bool) {
        isActive = true
        timerIsActive = true
        
        if !isRestoring {
            startTime = Date()
            timerEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
        }
        
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
        timerIsActive = false
        timerEndTime = 0
        timer?.invalidate()
        timer = nil
        
        // Cancelar notificaciones si se pausa el timer
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func completeSession(wasCompleted: Bool) {
        pauseTimer()
        
        // Haptic feedback para sesión completada
        if wasCompleted {
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
                heavyImpact.prepare()
                heavyImpact.impactOccurred()
            }
        } else {
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.warning)
        }
        
        // Guardar sesión
        if let startTime = startTime {
            let totalDuration = getDuration(for: currentType)
            let elapsedTime = totalDuration - timeRemaining
            
            Task {
                await dataService.saveSession(
                    startDate: startTime,
                    endDate: Date(),
                    duration: elapsedTime,
                    type: currentType,
                    wasCompleted: wasCompleted
                )
            }
        }
        
        if wasCompleted {
            // Solo reproducir sonido si la app está activa
            if UIApplication.shared.applicationState == .active {
                if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
                    soundService.playSound(for: currentType)
                }
            }
            
            // Actualizar contador de sesiones ANTES de cambiar el tipo
            if currentType == .work {
                completedSessions += 1
                persistedCompletedSessions = completedSessions
            }
        }
        
        // Cambiar al siguiente tipo
        switchToNextType()
        resetTimer()
    }
    
    private func switchToNextType() {
        let previousType = currentType
        
        switch currentType {
        case .work:
            if completedSessions > 0 && completedSessions % sessionsUntilLongBreakSetting == 0 {
                currentType = .longBreak
            } else {
                currentType = .shortBreak
            }
        case .shortBreak, .longBreak:
            currentType = .work
        }
        
        // Persistir inmediatamente el nuevo tipo
        timerTypeRaw = currentType.rawValue
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
