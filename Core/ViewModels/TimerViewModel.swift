// Core/ViewModels/TimerViewModel.swift

import Foundation
import SwiftUI
import Combine
import UIKit
import ActivityKit

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
    @AppStorage("savedTimeRemaining") private var savedTimeRemaining: Int = 0
    @AppStorage("isPaused") private var isPaused: Bool = false // Nuevo estado para pausado
    @AppStorage("totalSessionDuration") private var totalSessionDuration: Int = 0 // Duración total de la sesión actual
    
    // Quick Actions
    @AppStorage("shouldStartTimer") private var shouldStartTimer: Bool = false
    @AppStorage("quickActionTimerType") private var quickActionTimerType: String = ""
    
    private var timer: Timer?
    private var sessionStartTime: Date?
    private let soundService = SoundService()
    private let notificationService = NotificationService()
    private let reviewService = ReviewService.shared
    let dataService = DataService()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Haptic feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    // Live Activity
    private let liveActivityManager = LiveActivityManager.shared
    private var actionPollingTimer: Timer?

    // Timer para verificar el cambio de día
    private var midnightTimer: Timer?
    
    // Variables para rastrear valores anteriores de configuración
    private var previousWorkDuration: Int = 0
    private var previousShortBreakDuration: Int = 0
    private var previousLongBreakDuration: Int = 0
    private var isUpdatingSettings = false
    
    var progress: Double {
        // Si no hay duración total guardada, usar la duración del tipo actual
        let total = totalSessionDuration > 0 ? Double(totalSessionDuration) : Double(getDurationForType(currentType))
        guard total > 0 else { return 0 }
        
        // Calcular el progreso: 1.0 - (tiempo restante / tiempo total)
        let progressValue = 1.0 - (Double(timeRemaining) / total)
        
        // Asegurar que el progreso esté entre 0 y 1
        return max(0, min(1, progressValue))
    }
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var buttonTitle: String {
        isActive ? NSLocalizedString("PAUSE", comment: "Pause button title") : NSLocalizedString("START", comment: "Start button title")
    }
    
    init() {
        setupHaptics()
        
        // Inicializar valores anteriores
        previousWorkDuration = workDurationMinutes
        previousShortBreakDuration = shortBreakDurationMinutes
        previousLongBreakDuration = longBreakDurationMinutes
        
        restoreState()
        setupNotificationObservers()
        setupMidnightTimer()
        notificationService.cancelAllNotifications()
    }
    
    deinit {
        midnightTimer?.invalidate()
        actionPollingTimer?.invalidate()
    }
    
    private func setupHaptics() {
        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    private func setupMidnightTimer() {
        // Cancelar timer anterior si existe
        midnightTimer?.invalidate()
        
        // Calcular tiempo hasta medianoche
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let midnight = calendar.startOfDay(for: tomorrow)
        let timeUntilMidnight = midnight.timeIntervalSince(Date())
        
        // Configurar timer para medianoche
        midnightTimer = Timer.scheduledTimer(withTimeInterval: timeUntilMidnight, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.resetSessionsAtMidnight()
                self?.setupMidnightTimer() // Reconfigurar para el siguiente día
            }
        }
    }
    
    private func resetSessionsAtMidnight() {
        print("🌙 Medianoche detectada. Reiniciando contador de sesiones.")
        completedSessions = 0
        savedCompletedSessions = 0
        lastSessionDate = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
    }

    private func checkForQuickAction() {
        guard shouldStartTimer, let type = TimerType(rawValue: quickActionTimerType) else { return }

        shouldStartTimer = false

        if isActive {
            pauseTimer()
        }
        resetToInitialState()

        currentType = type
        timeRemaining = getDurationForType(type)
        savedTimerType = type.rawValue
        
        startTimer()
        
        quickActionTimerType = ""
    }
    
    private func restoreState() {
        completedSessions = savedCompletedSessions
        resetSessionsIfNeeded()
        
        if let type = TimerType(rawValue: savedTimerType) {
            currentType = type
        }
        
        // Restaurar estado pausado
        if isPaused && savedTimeRemaining > 0 {
            timeRemaining = savedTimeRemaining
            isActive = false
            // Si estamos pausados y tenemos duración total guardada, usarla
            if totalSessionDuration == 0 {
                totalSessionDuration = getDurationForType(currentType)
            }
        } else if savedTimeRemaining > 0 && !savedIsActive {
            timeRemaining = savedTimeRemaining
            if totalSessionDuration == 0 {
                totalSessionDuration = getDurationForType(currentType)
            }
        } else if savedIsActive && savedEndTime > Date().timeIntervalSince1970 {
            let remaining = Int(savedEndTime - Date().timeIntervalSince1970)
            if remaining > 0 {
                timeRemaining = remaining
                isActive = true
                // Restaurar la duración total si no está guardada
                if totalSessionDuration == 0 {
                    totalSessionDuration = getDurationForType(currentType)
                }
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
            .sink { [weak self] _ in
                self?.handleAppComingToForeground()
                self?.checkForQuickAction()
            }
            .store(in: &cancellables)
        
        // Observar cambios en UserDefaults para detectar cambios en las configuraciones
        // Usamos debounce para evitar múltiples llamadas consecutivas
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                // Solo procesar si el cambio viene de UserDefaults.standard
                if let userDefaults = notification.object as? UserDefaults,
                   userDefaults == UserDefaults.standard {
                    self.handleSettingsChange()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleSettingsChange() {
        // Prevenir re-entrada
        guard !isUpdatingSettings else { return }
        
        // Verificar si alguna duración ha cambiado
        let workChanged = previousWorkDuration != workDurationMinutes
        let shortBreakChanged = previousShortBreakDuration != shortBreakDurationMinutes
        let longBreakChanged = previousLongBreakDuration != longBreakDurationMinutes
        
        // Si hay cambios y el timer no está activo ni pausado, actualizar
        if (workChanged || shortBreakChanged || longBreakChanged) && !isActive && !isPaused {
            isUpdatingSettings = true
            
            // Actualizar los valores anteriores PRIMERO para evitar ciclos
            previousWorkDuration = workDurationMinutes
            previousShortBreakDuration = shortBreakDurationMinutes
            previousLongBreakDuration = longBreakDurationMinutes
            
            // Actualizar el tiempo restante con la nueva duración
            timeRemaining = getDurationForType(currentType)
            totalSessionDuration = 0  // Reiniciar la duración total cuando cambian los ajustes
            
            // Solo limpiar savedTimeRemaining si realmente es necesario
            if savedTimeRemaining > 0 && !isPaused {
                savedTimeRemaining = 0
            }
            
            print("⚙️ Configuración actualizada. Nuevo tiempo: \(timeRemaining) segundos")
            
            isUpdatingSettings = false
        }
    }
    
    private func handleAppGoingToBackground() {
        guard isActive else {
            if timeRemaining > 0 {
                savedTimeRemaining = timeRemaining
            }
            return
        }
        
        savedEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
        savedIsActive = true
        savedTimerType = currentType.rawValue
        savedCompletedSessions = completedSessions
        savedTimeRemaining = 0
        
        Task {
            await notificationService.scheduleTimerCompletionNotification(for: currentType, in: TimeInterval(timeRemaining))
        }
    }
    
    private func handleAppComingToForeground() {
        notificationService.cancelAllNotifications()
        resetSessionsIfNeeded()
        checkForLiveActivityAction()
        
        if !savedIsActive && savedTimeRemaining > 0 {
            timeRemaining = savedTimeRemaining
            return
        }
        
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
    
    private func handleTimerExpired() {
        timeRemaining = 0
        savedTimeRemaining = 0
        isPaused = false
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

        // Detener el timer si está activo
        if isActive {
            timer?.invalidate()
            timer = nil
            isActive = false
            savedIsActive = false
        }

        // Limpiar todos los estados guardados
        savedTimeRemaining = 0
        savedEndTime = 0
        isPaused = false
        sessionStartTime = nil
        totalSessionDuration = 0  // Reiniciar la duración total

        // Reiniciar al valor inicial del tipo actual
        resetToInitialState()

        notificationService.cancelAllNotifications()

        // Live Activity — keep DI showing paused/reset state
        updateLiveActivityState()
    }
    
    func skipSession() {
        guard isActive else { return }
        let lightImpact = UIImpactFeedbackGenerator(style: .light)
        lightImpact.impactOccurred()
        isPaused = false
        sessionCompleted(wasSkipped: true)
    }
    
    func changeTimerType(to type: TimerType) {
        guard !isActive && type != currentType else { return }
        selectionFeedback.selectionChanged()
        currentType = type
        savedTimerType = type.rawValue
        savedTimeRemaining = 0
        isPaused = false
        totalSessionDuration = 0  // Reiniciar cuando cambiamos de tipo
        timeRemaining = getDurationForType(type)
    }
    
    func startTimer() {
        // Si estamos reanudando desde pausa, usar el tiempo guardado
        if isPaused && savedTimeRemaining > 0 {
            timeRemaining = savedTimeRemaining
            isPaused = false
            savedTimeRemaining = 0 // Limpiar el tiempo guardado después de usarlo
        } else if savedTimeRemaining > 0 && !isPaused {
            // Si hay tiempo guardado pero no estamos pausados, usarlo
            timeRemaining = savedTimeRemaining
            savedTimeRemaining = 0
        }
        
        // Si es una nueva sesión (no pausada), guardar la duración total
        if totalSessionDuration == 0 || (!isPaused && sessionStartTime == nil) {
            totalSessionDuration = timeRemaining
        }
        
        isActive = true
        savedIsActive = true
        
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        
        savedEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
        startTimerCounting()

        // Live Activity
        let duration = totalSessionDuration > 0 ? totalSessionDuration : timeRemaining
        liveActivityManager.startLiveActivity(
            timerType: currentType,
            timeRemaining: timeRemaining,
            totalDuration: duration
        )
        startActionPolling()
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

            // Update Live Activity every 30s so the minimal DI progress ring advances
            if timeRemaining % 30 == 0 {
                updateLiveActivityState()
            }
        } else {
            sessionCompleted(wasSkipped: false)
        }
    }
    
    private func pauseTimer() {
        isActive = false
        savedIsActive = false
        savedEndTime = 0
        isPaused = true // Marcar como pausado
        
        // Guardar el tiempo actual
        if timeRemaining > 0 {
            savedTimeRemaining = timeRemaining
        }
        
        timer?.invalidate()
        timer = nil
        notificationService.cancelAllNotifications()

        // Live Activity
        updateLiveActivityState()
    }
    
    private func resetToInitialState() {
        timeRemaining = getDurationForType(currentType)
        totalSessionDuration = 0  // Reiniciar la duración total
        sessionStartTime = nil
        savedEndTime = 0
        savedIsActive = false
        savedTimeRemaining = 0
        isPaused = false
    }
    
    private func sessionCompleted(wasSkipped: Bool) {
        timer?.invalidate()
        timer = nil
        isActive = false
        savedIsActive = false
        savedTimeRemaining = 0
        isPaused = false
        totalSessionDuration = 0  // Reiniciar la duración total

        if !wasSkipped {
            notificationFeedback.notificationOccurred(.success)
        } else {
            notificationFeedback.notificationOccurred(.warning)
        }

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

        if !wasSkipped && UIApplication.shared.applicationState == .active {
            if UserDefaults.standard.bool(forKey: Constants.UserDefaults.isSoundEnabled) {
                soundService.playSound(for: currentType)
            }
        }

        if currentType == .work && !wasSkipped {
            resetSessionsIfNeeded()
            completedSessions += 1
            savedCompletedSessions = completedSessions

            Task {
                reviewService.recordCompletedPomodoro()
            }
        }

        if wasSkipped {
            // Skip: move to next session, update DI to show new state, keep polling
            moveToNextSessionType()
            resetToInitialState()
            updateLiveActivityState()
        } else {
            // Natural completion: dismiss DI
            liveActivityManager.endLiveActivity()
            stopActionPolling()
            moveToNextSessionType()
            resetToInitialState()
        }
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
    
    private func resetSessionsIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        let lastDate = Date(timeIntervalSince1970: lastSessionDate)
        
        if lastSessionDate == 0 || !calendar.isDate(now, inSameDayAs: lastDate) {
            completedSessions = 0
            savedCompletedSessions = 0
            print("🌅 Nueva jornada detectada. Reiniciando contador de sesiones.")
        }
        
        lastSessionDate = calendar.startOfDay(for: now).timeIntervalSince1970
    }
    
    // MARK: - Live Activity

    private func updateLiveActivityState() {
        let duration = totalSessionDuration > 0 ? totalSessionDuration : getDurationForType(currentType)
        liveActivityManager.updateLiveActivity(
            timerType: currentType,
            isRunning: isActive,
            timeRemaining: timeRemaining,
            totalDuration: duration
        )
    }

    private func checkForLiveActivityAction() {
        let defaults = UserDefaults(suiteName: Constants.LiveActivity.appGroupIdentifier)
        guard let actionString = defaults?.string(forKey: Constants.LiveActivity.pendingActionKey),
              let action = PomoTimerAction(rawValue: actionString) else { return }

        // Clear the pending action
        defaults?.removeObject(forKey: Constants.LiveActivity.pendingActionKey)
        defaults?.removeObject(forKey: Constants.LiveActivity.actionTimestampKey)

        switch action {
        case .play:
            if !isActive {
                startTimer()
            }
        case .pause:
            if isActive {
                pauseTimer()
            }
        case .reset:
            resetTimer()
        case .skip:
            if isActive {
                skipSession()
            }
        }
    }

    private func startActionPolling() {
        actionPollingTimer?.invalidate()
        actionPollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in self.checkForLiveActivityAction() }
        }
    }

    private func stopActionPolling() {
        actionPollingTimer?.invalidate()
        actionPollingTimer = nil
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
