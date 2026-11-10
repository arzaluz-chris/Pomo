// ReviewService.swift

import Foundation
import StoreKit
import SwiftUI

@MainActor
class ReviewService: ObservableObject {
    static let shared = ReviewService()
    
    // Keys para UserDefaults
    private let completedPomodorosKey = "completedPomodorosForReview"
    private let lastReviewRequestDateKey = "lastReviewRequestDate"
    private let hasRequestedReviewKey = "hasRequestedReview"
    private let appFirstLaunchDateKey = "appFirstLaunchDate"
    private let totalSessionsKey = "totalSessionsCompleted"
    
    // Configuración de cuándo pedir reseñas
    private let pomodorosForFirstRequest = 10  // Después de 10 pomodoros completados
    private let pomodorosForSubsequentRequests = 50  // Cada 50 pomodoros después
    private let minimumDaysBetweenRequests = 60  // No pedir más de una vez cada 2 meses
    private let minimumDaysAfterInstall = 3  // Esperar al menos 3 días después de la instalación
    
    @AppStorage("completedPomodorosForReview") private var completedPomodoros = 0
    @AppStorage("lastReviewRequestDate") private var lastReviewRequestTimestamp: Double = 0
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    @AppStorage("appFirstLaunchDate") private var firstLaunchTimestamp: Double = 0
    @AppStorage("totalSessionsCompleted") private var totalSessions = 0
    
    init() {
        // Registrar primera ejecución si es necesario
        if firstLaunchTimestamp == 0 {
            firstLaunchTimestamp = Date().timeIntervalSince1970
        }
    }
    
    /// Registra un pomodoro completado y verifica si es momento de pedir una reseña
    func recordCompletedPomodoro() {
        completedPomodoros += 1
        totalSessions += 1
        
        // Verificar si debemos solicitar una reseña
        checkAndRequestReviewIfAppropriate()
    }
    
    /// Verifica las condiciones y solicita una reseña si es apropiado
    private func checkAndRequestReviewIfAppropriate() {
        // Verificar que hayan pasado suficientes días desde la instalación
        let daysSinceInstall = daysSince(timestamp: firstLaunchTimestamp)
        guard daysSinceInstall >= minimumDaysAfterInstall else {
            print("📝 Review: Esperando más tiempo desde la instalación (\(daysSinceInstall) días)")
            return
        }
        
        // Verificar que hayan pasado suficientes días desde la última solicitud
        if lastReviewRequestTimestamp > 0 {
            let daysSinceLastRequest = daysSince(timestamp: lastReviewRequestTimestamp)
            guard daysSinceLastRequest >= minimumDaysBetweenRequests else {
                print("📝 Review: Esperando más tiempo desde la última solicitud (\(daysSinceLastRequest) días)")
                return
            }
        }
        
        // Determinar el umbral de pomodoros necesarios
        let threshold = hasRequestedReview ? pomodorosForSubsequentRequests : pomodorosForFirstRequest
        
        // Verificar si hemos alcanzado el umbral
        if completedPomodoros >= threshold {
            requestReview()
            
            // Resetear contador y actualizar timestamp
            completedPomodoros = 0
            lastReviewRequestTimestamp = Date().timeIntervalSince1970
            hasRequestedReview = true
        }
    }
    
    /// Solicita una reseña usando el API nativo de iOS
    func requestReview() {
        // Usar un pequeño delay para no interrumpir la experiencia del usuario
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
            
            if let scene = activeWindowScene {
                AppStore.requestReview(in: scene)
                print("📝 Review: Solicitando reseña al usuario")
            }
        }
    }
    
    /// Solicitud manual de reseña (desde Quick Actions o Settings)
    func requestManualReview() {
        if let scene = activeWindowScene {
            AppStore.requestReview(in: scene)
        }
    }

    /// The system ignores review requests without a foreground scene (e.g. when a session
    /// completes while the app runs in the background).
    private var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
    
    /// Abre directamente la página de reseñas en App Store
    func openAppStoreForReview() {
        // Apple ID de Pomo en App Store Connect ("Pomo Simple Timer")
        let appStoreURL = "https://apps.apple.com/app/id6746705227?action=write-review"
        
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
    
    // Helper para calcular días transcurridos
    private func daysSince(timestamp: Double) -> Int {
        let date = Date(timeIntervalSince1970: timestamp)
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return days
    }
    
    // Estadísticas para debug (opcional)
    var debugStats: String {
        """
        📊 Review Service Stats:
        - Pomodoros completados (para review): \(completedPomodoros)
        - Total de sesiones: \(totalSessions)
        - Días desde instalación: \(daysSince(timestamp: firstLaunchTimestamp))
        - Días desde última solicitud: \(lastReviewRequestTimestamp > 0 ? "\(daysSince(timestamp: lastReviewRequestTimestamp))" : "Nunca")
        - Ha solicitado reseña: \(hasRequestedReview ? "Sí" : "No")
        - Próxima solicitud en: \(hasRequestedReview ? "\(pomodorosForSubsequentRequests - completedPomodoros)" : "\(pomodorosForFirstRequest - completedPomodoros)") pomodoros
        """
    }
}
