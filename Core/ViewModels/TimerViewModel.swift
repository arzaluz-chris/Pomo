// Core/ViewModels/TimerViewModel.swift

import Foundation
import SwiftUI
import Combine
import UIKit
import ActivityKit
import SwiftData
import WatchConnectivity

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
    
    // Identity and start of the current session, shared with Apple Watch. Persisted so a
    // session that ends while the app is terminated is still recorded. Either device may
    // record it; the session ID lets the iPhone store drop the duplicate.
    @AppStorage("savedSessionID") private var sessionID: String = ""
    @AppStorage("savedSessionStartTime") private var savedSessionStartTime: Double = 0
    private var sessionStartTime: Date? {
        get { savedSessionStartTime > 0 ? Date(timeIntervalSince1970: savedSessionStartTime) : nil }
        set { savedSessionStartTime = newValue?.timeIntervalSince1970 ?? 0 }
    }

    private var timer: Timer?
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

    // Timer para verificar el cambio de día
    private var midnightTimer: Timer?
    
    // Variables para rastrear valores anteriores de configuración
    private var previousWorkDuration: Int = 0
    private var previousShortBreakDuration: Int = 0
    private var previousLongBreakDuration: Int = 0
    private var isUpdatingSettings = false

    // Watch sync timestamp
    @AppStorage("lastActionTimestamp") private var lastActionTimestamp: Double = 0
    
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
    
    init(modelContainer: ModelContainer) {
        // Attach storage before restoring state: a session that finished while the app was
        // closed is saved during restoreState()
        dataService.setModelContext(modelContainer.mainContext)

        setupHaptics()
        
        // Inicializar valores anteriores
        previousWorkDuration = workDurationMinutes
        previousShortBreakDuration = shortBreakDurationMinutes
        previousLongBreakDuration = longBreakDurationMinutes
        
        restoreState()
        setupNotificationObservers()
        setupMidnightTimer()
        setupWatchConnectivityCallbacks()
        // Apply an action a Live Activity button stored while the app could not handle it
        checkForLiveActivityAction()
    }
    
    deinit {
        midnightTimer?.invalidate()
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
                notificationService.scheduleCompletion(for: currentType, at: Date(timeIntervalSince1970: savedEndTime))
            } else {
                handleTimerExpired()
            }
        } else if savedIsActive {
            // The session ended while the app was not running: record it instead of dropping it
            handleTimerExpired()
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

        // savedEndTime is the source of truth while running (set on start); don't recompute
        // it from the tick counter, which can drift. The alert was scheduled on start.
        savedIsActive = true
        savedTimerType = currentType.rawValue
        savedCompletedSessions = completedSessions
        savedTimeRemaining = 0
    }
    
    private func handleAppComingToForeground() {
        // Only clear alerts already shown; the pending one must survive while the timer runs
        notificationService.clearDelivered()
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
        // Record the session at its real end time, not when the app noticed it
        let endDate = savedEndTime > 0 ? Date(timeIntervalSince1970: min(savedEndTime, Date().timeIntervalSince1970)) : Date()
        timeRemaining = 0
        savedTimeRemaining = 0
        isPaused = false
        sessionCompleted(wasSkipped: false, endDate: endDate)
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

        notificationService.cancelCompletion()

        // Live Activity — keep DI showing paused/reset state
        updateLiveActivityState()

        // Sync to Watch
        syncStateToWatch()
    }
    
    func skipSession() {
        // Paused sessions can be skipped too (the Live Activity shows Skip while paused)
        guard isActive || isPaused else { return }
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
        
        // Nueva sesión: guardar la duración total (al reanudar se conserva la original)
        if totalSessionDuration == 0 {
            totalSessionDuration = timeRemaining
        }
        
        isActive = true
        savedIsActive = true
        
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        if sessionID.isEmpty {
            sessionID = UUID().uuidString
        }
        
        savedEndTime = Date().timeIntervalSince1970 + Double(timeRemaining)
        startTimerCounting()

        // Alert at the end of the session, whatever state the app is in when it ends
        notificationService.scheduleCompletion(for: currentType, at: Date(timeIntervalSince1970: savedEndTime))

        // Live Activity
        let duration = totalSessionDuration > 0 ? totalSessionDuration : timeRemaining
        liveActivityManager.startLiveActivity(
            timerType: currentType,
            timeRemaining: timeRemaining,
            totalDuration: duration
        )

        // Sync to Watch
        syncStateToWatch()
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
        notificationService.cancelCompletion()

        // Live Activity
        updateLiveActivityState()

        // Sync to Watch
        syncStateToWatch()
    }
    
    private func resetToInitialState() {
        timeRemaining = getDurationForType(currentType)
        totalSessionDuration = 0  // Reiniciar la duración total
        sessionStartTime = nil
        sessionID = ""
        savedEndTime = 0
        savedIsActive = false
        savedTimeRemaining = 0
        isPaused = false
    }
    
    private func sessionCompleted(wasSkipped: Bool, endDate: Date = Date()) {
        // Capture the planned length before the state is cleared
        let plannedDuration = totalSessionDuration > 0 ? totalSessionDuration : getDurationForType(currentType)

        timer?.invalidate()
        timer = nil
        isActive = false
        savedIsActive = false
        savedTimeRemaining = 0
        isPaused = false
        totalSessionDuration = 0  // Reiniciar la duración total
        notificationService.cancelCompletion()

        if !wasSkipped {
            notificationFeedback.notificationOccurred(.success)
        } else {
            notificationFeedback.notificationOccurred(.warning)
        }

        if let startTime = sessionStartTime {
            let duration = max(0, plannedDuration - timeRemaining)
            let type = currentType
            let id = sessionID.isEmpty ? UUID().uuidString : sessionID
            Task {
                await dataService.saveSession(
                    startDate: startTime,
                    endDate: endDate,
                    duration: duration,
                    type: type,
                    wasCompleted: !wasSkipped,
                    sessionID: id
                )
            }
            sendCompletedSessionToWatch(startTime, endDate: endDate, duration: duration, wasSkipped: wasSkipped, sessionID: id)
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
            // Skip: move to next session, update DI to show new state
            moveToNextSessionType()
            resetToInitialState()
            updateLiveActivityState()
        } else {
            // Natural completion: dismiss DI
            liveActivityManager.endLiveActivity()
            moveToNextSessionType()
            resetToInitialState()
        }

        // Sync to Watch
        syncStateToWatch()
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

    /// Runs a Live Activity / Dynamic Island button action. Called directly from the
    /// intent's perform(), which the system runs in the app's process (relaunching it in the
    /// background if needed), so the change applies even when the app isn't open. Waits for
    /// the Live Activity update and the alert (re)scheduling before returning, because the
    /// system may suspend the app right after perform() finishes.
    func perform(_ action: PomoTimerAction) async {
        // Bring state up to date first: the session may have ended while the app was suspended
        reconcileWithClock()

        switch action {
        case .play:
            if !isActive {
                resetSessionsIfNeeded()
                startTimer()
            }
        case .pause:
            if isActive {
                pauseTimer()
            }
        case .reset:
            resetTimer()
        case .skip:
            skipSession()
        }

        await liveActivityManager.waitForPendingUpdates()
        await notificationService.waitForPendingWork()
    }

    /// Recomputes the remaining time from the saved end date (the 1 s tick counter stops
    /// while the app is suspended) and completes the session if it already ended.
    private func reconcileWithClock() {
        guard isActive, savedEndTime > 0 else { return }
        let remaining = Int(savedEndTime - Date().timeIntervalSince1970)
        if remaining > 0 {
            timeRemaining = remaining
        } else {
            handleTimerExpired()
        }
    }

    /// Fallback for actions stored by an intent that ran outside the app's process.
    private func checkForLiveActivityAction() {
        let defaults = UserDefaults(suiteName: Constants.AppGroup.identifier)
        guard let actionString = defaults?.string(forKey: Constants.LiveActivity.pendingActionKey),
              let action = PomoTimerAction(rawValue: actionString) else { return }

        defaults?.removeObject(forKey: Constants.LiveActivity.pendingActionKey)
        defaults?.removeObject(forKey: Constants.LiveActivity.actionTimestampKey)

        Task { await perform(action) }
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

    // MARK: - Watch Connectivity Sync

    private func syncStateToWatch() {
        let state = TimerStateSync(
            currentType: currentType,
            timeRemaining: timeRemaining,
            isActive: isActive,
            isPaused: isPaused,
            completedSessions: completedSessions,
            totalSessionDuration: totalSessionDuration,
            endTime: isActive ? savedEndTime : nil,
            sessionID: (isActive || isPaused) && !sessionID.isEmpty ? sessionID : nil,
            sessionStartDate: (isActive || isPaused) ? sessionStartTime?.timeIntervalSince1970 : nil
        )
        lastActionTimestamp = state.timestamp
        WatchConnectivityManager.shared.syncTimerState(state)
    }

    private func sendCompletedSessionToWatch(_ startTime: Date, endDate: Date, duration: Int, wasSkipped: Bool, sessionID: String) {
        let session = SessionSync(
            id: UUID(uuidString: sessionID) ?? UUID(),
            startDate: startTime,
            endDate: endDate,
            duration: duration,
            type: currentType,
            wasCompleted: !wasSkipped,
            originDevice: "iPhone"
        )
        WatchConnectivityManager.shared.syncCompletedSession(session)
    }

    private func setupWatchConnectivityCallbacks() {
        WatchConnectivityManager.shared.onTimerStateReceived = { [weak self] state in
            Task { @MainActor in
                self?.applyReceivedTimerState(state)
            }
        }

        WatchConnectivityManager.shared.onSessionReceived = { [weak self] session in
            Task { @MainActor in
                self?.applyReceivedSession(session)
            }
        }

        WatchConnectivityManager.shared.onSettingsReceived = { [weak self] settings in
            Task { @MainActor in
                self?.applyReceivedSettings(settings)
            }
        }
    }

    private func applyReceivedTimerState(_ state: TimerStateSync) {
        guard state.timestamp > lastActionTimestamp else { return }

        // Remember the newest state applied so an older message arriving late is ignored
        lastActionTimestamp = max(lastActionTimestamp, state.timestamp)

        timer?.invalidate()
        timer = nil

        // Adopt the shared session identity so this device can record the session if it is
        // the first to notice it ended (the iPhone store drops the duplicate by ID)
        if let remoteID = state.sessionID {
            sessionID = remoteID
        }
        if let remoteStart = state.sessionStartDate {
            savedSessionStartTime = remoteStart
        }

        currentType = state.timerType
        savedTimerType = state.currentType
        completedSessions = state.completedSessions
        savedCompletedSessions = state.completedSessions
        totalSessionDuration = state.totalSessionDuration
        isPaused = state.isPaused

        if state.isActive, let endTime = state.endTime {
            let remaining = Int(endTime - Date().timeIntervalSince1970)
            if remaining > 0 {
                timeRemaining = remaining
                isActive = true
                savedIsActive = true
                savedEndTime = endTime
                savedTimeRemaining = 0
                startTimerCounting()
                // Both devices alert, with the same identifier, so the system can coordinate them
                notificationService.scheduleCompletion(for: currentType, at: Date(timeIntervalSince1970: endTime))
                updateLiveActivityState()
            } else {
                savedEndTime = endTime
                savedIsActive = true
                handleTimerExpired()
            }
        } else if state.isPaused {
            timeRemaining = state.timeRemaining
            isActive = false
            savedIsActive = false
            savedEndTime = 0
            savedTimeRemaining = state.timeRemaining
            notificationService.cancelCompletion()
            updateLiveActivityState()
        } else {
            isActive = false
            savedIsActive = false
            savedEndTime = 0
            savedTimeRemaining = 0
            sessionStartTime = nil
            sessionID = ""
            timeRemaining = getDurationForType(state.timerType)
            totalSessionDuration = 0
            notificationService.cancelCompletion()
            liveActivityManager.endLiveActivity()
        }
    }

    private func applyReceivedSession(_ session: SessionSync) {
        // Dedup: check if session with this UUID already exists
        Task {
            await dataService.saveSession(
                startDate: session.startDate,
                endDate: session.endDate,
                duration: session.duration,
                type: session.timerType,
                wasCompleted: session.wasCompleted,
                sessionID: session.id.uuidString
            )
        }
    }

    private func applyReceivedSettings(_ settings: SettingsSync) {
        isUpdatingSettings = true
        workDurationMinutes = settings.workDuration
        shortBreakDurationMinutes = settings.shortBreakDuration
        longBreakDurationMinutes = settings.longBreakDuration
        sessionsUntilLongBreak = settings.sessionsUntilLongBreak

        previousWorkDuration = settings.workDuration
        previousShortBreakDuration = settings.shortBreakDuration
        previousLongBreakDuration = settings.longBreakDuration

        if !isActive && !isPaused {
            timeRemaining = getDurationForType(currentType)
            totalSessionDuration = 0
        }

        isUpdatingSettings = false
    }
}
