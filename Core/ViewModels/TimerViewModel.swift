// Core/ViewModels/TimerViewModel.swift

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
    @AppStorage("lastSessionDate") private var lastSessionDate: Double = 0
    
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
        // Evita la división por cero si la duración es 0
        return total > 0 ? 1.0 - (Double(timeRemaining) / total) : 0
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
        
        notificationService.cancelAllNotifications()
    }
    
    private func setupHaptics() {
        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    private func restoreState() {
        completedSessions = savedCompletedSessions
        resetSessionsIfNeeded()
        
        if let type = TimerType(rawValue: savedTimerType) {
            currentType = type
        }
        
        if savedIsActive && savedEndTime > Date().timeIntervalSince1970 {
            let remaining = Int(savedEndTime - Date().timeIntervalSince1970)
            if remaining > 0 {
                timeRemaining = remaining
                isActive = true
                startTimerCounting()
            } else {
                handleTimerExpired()
            }
        } else {
            resetToInitialState()
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.handleAppGoingToBackground() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in Task { @MainActor in self?.handleAppComingToForeground() } }
            .store(in: &cancellables)
        
        // Observador para cambios en UserDefaults (Configuración)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in Task { @MainActor in self?.handleSettingsChange() } }
            .store(in: &cancellables)
    }
    
    private func handleAppGoingToBackground() {
        guard isActive else { return }
        
        savedEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
        savedIsActive = true
        savedTimerType = currentType.rawValue
        savedCompletedSessions = completedSessions
        
        Task {
            await notificationService.scheduleTimerCompletionNotification(for: currentType, in: TimeInterval(timeRemaining))
        }
    }
    
    private func handleAppComingToForeground() {
        notificationService.cancelAllNotifications()
        resetSessionsIfNeeded()
        guard savedIsActive else { return }
        
        let now = Date().timeIntervalSince1970
        if savedEndTime > now {
            timeRemaining = Int(savedEndTime - now)
            if !isActive {
                isActive = true
                startTimerCounting()
            }
        } else {
            handleTimerExpired()
        }
    }
    
    // --- LÓGICA CORREGIDA (BUG #1) ---
    private func handleSettingsChange() {
        // Solo actualiza si el temporizador está pausado o no ha comenzado.
        guard !isActive else { return }
        
        // Actualiza el tiempo restante para que refleje inmediatamente el nuevo valor de la configuración.
        timeRemaining = getDurationForType(currentType)
    }
    
    private func handleTimerExpired() {
        timeRemaining = 0
        sessionCompleted(wasSkipped: false)
    }
    
    func toggleTimer() {
        impactFeedback.impactOccurred()
        if isActive {
            pauseTimer()
        } else {
            resetSessionsIfNeeded()
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
            Task { @MainActor in self.updateTimer() }
        }
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            sessionCompleted(wasSkipped: false)
        }
    }
    
    // --- LÓGICA CORRECTA (BUG #2) ---
    private func pauseTimer() {
        isActive = false
        savedIsActive = false
        savedEndTime = 0 // El tiempo final se recalculará al reanudar
        timer?.invalidate()
        timer = nil
        notificationService.cancelAllNotifications()
        // IMPORTANTE: No se modifica `timeRemaining` para que se conserve el progreso.
    }
    
    private func resetToInitialState() {
        timeRemaining = getDurationForType(currentType)
        sessionStartTime = nil
        savedEndTime = 0
        savedIsActive = false
    }
    
    private func sessionCompleted(wasSkipped: Bool) {
        timer?.invalidate()
        timer = nil
        isActive = false
        savedIsActive = false
        
        if !wasSkipped {
            notificationFeedback.notificationOccurred(.success)
        } else {
            notificationFeedback.notificationOccurred(.warning)
        }
        
        if let startTime = sessionStartTime {
            let duration = getDurationForType(currentType) - timeRemaining
            Task {
                await dataService.saveSession(startDate: startTime, endDate: Date(), duration: duration, type: currentType, wasCompleted: !wasSkipped)
            }
        }
        
        if !wasSkipped && UIApplication.shared.applicationState == .active {
            if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
                soundService.playSound(for: currentType)
            }
        }
        
        if currentType == .work && !wasSkipped {
            resetSessionsIfNeeded()
            completedSessions += 1
            savedCompletedSessions = completedSessions
        }
        
        moveToNextSessionType()
        resetToInitialState()
    }
    
    private func moveToNextSessionType() {
        switch currentType {
        case .work:
            if completedSessions > 0 && completedSessions % sessionsUntilLongBreak == 0 {
                currentType = .longBreak
            } else {
                currentType = .shortBreak
            }
        case .shortBreak, .longBreak:
            currentType = .work
        }
        savedTimerType = currentType.rawValue
    }

    // --- LÓGICA EXISTENTE Y CORRECTA (BUG #3) ---
    private func resetSessionsIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        let lastDate = Date(timeIntervalSince1970: lastSessionDate)

        // Si es la primera vez que se usa o si el día actual no es el mismo que el de la última sesión...
        if lastSessionDate == 0 || !calendar.isDate(now, inSameDayAs: lastDate) {
            // ...reinicia el contador de sesiones.
            completedSessions = 0
            savedCompletedSessions = 0
            print("🌅 Medianoche detectada o primer uso del día. Reiniciando contador de sesiones.")
        }

        // Actualiza la fecha de la última sesión al inicio del día de hoy.
        lastSessionDate = calendar.startOfDay(for: now).timeIntervalSince1970
    }

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
