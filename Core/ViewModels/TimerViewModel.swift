// TimerViewModel.swift
// Ubicación: Core/ViewModels/TimerViewModel.swift

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
    
    // IMPORTANTE: Inicializar correctamente los valores de notificaciones y sonido
    @AppStorage(Constants.UserDefaults.isNotificationEnabled) private var isNotificationEnabled: Bool = true
    @AppStorage(Constants.UserDefaults.isSoundEnabled) private var isSoundEnabled: Bool = true
    
    // Estado persistente del timer
    @AppStorage("savedTimerEndTime") private var savedEndTime: Double = 0
    @AppStorage("savedTimerIsActive") private var savedIsActive: Bool = false
    @AppStorage("savedTimerType") private var savedTimerType: String = TimerType.work.rawValue
    @AppStorage("savedCompletedSessions") private var savedCompletedSessions: Int = 0
    
    // Live Activity
    private var currentActivity: Activity<PomoActivityAttributes>?
    
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
        // Inicializar valores por defecto si es la primera vez
        initializeDefaultValues()
        setupHaptics()
        restoreState()
        setupNotificationObservers()
        setupLiveActivityObservers()
        
        // Limpiar notificaciones al iniciar
        notificationService.cancelAllNotifications()
        
        // Limpiar Live Activities huérfanas
        Task {
            await cleanupOrphanedLiveActivities()
        }
    }
    
    private func initializeDefaultValues() {
        // Si es la primera vez que se ejecuta la app, establecer valores por defecto
        if UserDefaults.standard.object(forKey: Constants.UserDefaults.isNotificationEnabled) == nil {
            UserDefaults.standard.set(true, forKey: Constants.UserDefaults.isNotificationEnabled)
        }
        if UserDefaults.standard.object(forKey: Constants.UserDefaults.isSoundEnabled) == nil {
            UserDefaults.standard.set(true, forKey: Constants.UserDefaults.isSoundEnabled)
        }
    }
    
    private func cleanupOrphanedLiveActivities() async {
        // Finalizar todas las actividades que no sean del tipo actual
        for activity in Activity<PomoActivityAttributes>.activities {
            if activity.attributes.sessionType != currentType.rawValue {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
    
    private func setupHaptics() {
        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    private func setupLiveActivityObservers() {
        // Observar cambios desde Live Activity - Toggle Pause
        NotificationCenter.default.publisher(for: Notification.Name("LiveActivityTogglePause"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let sessionType = userInfo["sessionType"] as? String,
                      sessionType == self.currentType.rawValue,
                      let isPaused = userInfo["isPaused"] as? Bool else { return }
                
                // Actualizar el estado local basado en el estado de Live Activity
                if isPaused && self.isActive {
                    self.pauseTimerFromLiveActivity()
                } else if !isPaused && !self.isActive {
                    self.startTimerFromLiveActivity()
                }
            }
            .store(in: &cancellables)
        
        // Observar cambios desde Live Activity - Reset
        NotificationCenter.default.publisher(for: Notification.Name("LiveActivityReset"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let sessionType = userInfo["sessionType"] as? String,
                      sessionType == self.currentType.rawValue else { return }
                
                self.resetTimer()
            }
            .store(in: &cancellables)
        
        // Observar cambios desde App Group UserDefaults
        if let _ = UserDefaults(suiteName: "group.com.christian-arzaluz.pomo") {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [unowned self] _ in
                guard let userDefaults = UserDefaults(suiteName: "group.com.christian-arzaluz.pomo") else { return }
                Task { @MainActor in
                    self.checkAppGroupUpdates(userDefaults)
                }
            }
        }
    }
    
    private func checkAppGroupUpdates(_ userDefaults: UserDefaults) {
        let sessionType = currentType.rawValue
        
        // Verificar si hubo un reset
        if userDefaults.bool(forKey: "LiveActivity_Reset_\(sessionType)") {
            userDefaults.removeObject(forKey: "LiveActivity_Reset_\(sessionType)")
            resetTimer()
            return
        }
        
        // Verificar cambios en pausa/reanudar
        if let lastUpdate = userDefaults.object(forKey: "LiveActivity_LastUpdate_\(sessionType)") as? TimeInterval {
            let timeSinceUpdate = Date().timeIntervalSince1970 - lastUpdate
            
            // Solo procesar si la actualización es reciente (menos de 2 segundos)
            if timeSinceUpdate < 2.0 {
                let isPausedInLiveActivity = userDefaults.bool(forKey: "LiveActivity_IsPaused_\(sessionType)")
                
                if isPausedInLiveActivity != !isActive {
                    if isPausedInLiveActivity && isActive {
                        pauseTimerFromLiveActivity()
                    } else if !isPausedInLiveActivity && !isActive {
                        if let timeRemaining = userDefaults.object(forKey: "LiveActivity_TimeRemaining_\(sessionType)") as? Int {
                            self.timeRemaining = timeRemaining
                        }
                        startTimerFromLiveActivity()
                    }
                }
                
                // Limpiar después de procesar
                userDefaults.removeObject(forKey: "LiveActivity_LastUpdate_\(sessionType)")
            }
        }
    }
    
    private func startTimerFromLiveActivity() {
        // Evitar recursión infinita
        guard !isActive else { return }
        
        isActive = true
        savedIsActive = true
        sessionStartTime = Date()
        savedEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
        
        startTimerCounting()
    }
    
    private func pauseTimerFromLiveActivity() {
        // Evitar recursión infinita
        guard isActive else { return }
        
        isActive = false
        savedIsActive = false
        savedEndTime = 0
        timer?.invalidate()
        timer = nil
        
        notificationService.cancelAllNotifications()
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
                restoreLiveActivity()
            } else {
                // El timer expiró mientras la app estaba cerrada
                handleTimerExpired()
            }
        } else {
            // No hay timer activo
            resetToInitialState()
        }
    }
    
    private func restoreLiveActivity() {
        // Buscar actividad existente
        if let activity = Activity<PomoActivityAttributes>.activities.first(where: {
            $0.attributes.sessionType == currentType.rawValue
        }) {
            currentActivity = activity
            // Actualizar con el estado actual
            Task {
                await updateLiveActivity()
            }
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
        
        // Programar notificación solo si está habilitada
        if isNotificationEnabled {
            Task {
                await notificationService.scheduleTimerCompletionNotification(
                    for: currentType,
                    in: TimeInterval(timeRemaining)
                )
            }
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
    
    // MARK: - Live Activity Management
    
    private func startLiveActivity() async {
        // Verificar permisos
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities no están habilitadas")
            return
        }
        
        // Finalizar TODAS las actividades anteriores para evitar duplicados
        for activity in Activity<PomoActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        
        let attributes = PomoActivityAttributes(
            sessionType: currentType.rawValue,
            totalDuration: getDurationForType(currentType),
            sessionNumber: currentType == .work ? completedSessions + 1 : 0
        )
        
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(TimeInterval(timeRemaining))
        
        let contentState = PomoActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            isPaused: false,
            endTime: endTime,
            startTime: startTime
        )
        
        do {
            currentActivity = try Activity<PomoActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            print("Live Activity iniciada para \(currentType.displayName)")
        } catch {
            print("Error al iniciar Live Activity: \(error)")
        }
    }
    
    private func updateLiveActivity() async {
        guard let activity = currentActivity else { return }
        
        let contentState: PomoActivityAttributes.ContentState
        
        if isActive {
            // Timer activo
            let endTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
            let totalDuration = getDurationForType(currentType)
            let startTime = endTime.addingTimeInterval(-TimeInterval(totalDuration))
            
            contentState = PomoActivityAttributes.ContentState(
                timeRemaining: timeRemaining,
                isPaused: false,
                endTime: endTime,
                startTime: startTime
            )
        } else {
            // Timer pausado
            contentState = PomoActivityAttributes.ContentState(
                timeRemaining: timeRemaining,
                isPaused: true,
                endTime: Date(),
                startTime: activity.content.state.startTime
            )
        }
        
        await activity.update(ActivityContent(state: contentState, staleDate: nil))
    }
    
    private func endLiveActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalState = PomoActivityAttributes.ContentState(
            timeRemaining: 0,
            isPaused: true,
            endTime: Date(),
            startTime: activity.content.state.startTime
        )
        
        await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        currentActivity = nil
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
        
        // Actualizar Live Activity
        Task {
            await updateLiveActivity()
        }
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
        
        // Iniciar o actualizar Live Activity
        Task {
            if currentActivity == nil {
                await startLiveActivity()
            } else {
                await updateLiveActivity()
            }
        }
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
            
            // Actualizar Live Activity cada 5 segundos para ahorrar batería
            if timeRemaining % 5 == 0 {
                Task {
                    await updateLiveActivity()
                }
            }
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
        
        // Actualizar Live Activity
        Task {
            await updateLiveActivity()
        }
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
        
        // Reproducir sonido solo si está habilitado y la app está activa
        if !wasSkipped && UIApplication.shared.applicationState == .active && isSoundEnabled {
            soundService.playSound(for: currentType)
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
        
        // Finalizar Live Activity
        Task {
            await endLiveActivity()
        }
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
