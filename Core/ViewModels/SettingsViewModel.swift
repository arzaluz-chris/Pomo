// SettingsViewModel.swift
// Ubicación: Core/ViewModels/SettingsViewModel.swift

import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage(Constants.UserDefaults.workDuration) var workDuration: Int = Constants.Defaults.workDuration / 60
    @AppStorage(Constants.UserDefaults.shortBreakDuration) var shortBreakDuration: Int = Constants.Defaults.shortBreakDuration / 60
    @AppStorage(Constants.UserDefaults.longBreakDuration) var longBreakDuration: Int = Constants.Defaults.longBreakDuration / 60
    @AppStorage(Constants.UserDefaults.sessionsUntilLongBreak) var sessionsUntilLongBreak: Int = Constants.Defaults.sessionsUntilLongBreak
    @AppStorage(Constants.UserDefaults.isNotificationEnabled) var isNotificationEnabled: Bool = true {
        didSet {
            print("isNotificationEnabled changed to: \(isNotificationEnabled)")
        }
    }
    @AppStorage(Constants.UserDefaults.isSoundEnabled) var isSoundEnabled: Bool = true
    
    private let notificationService = NotificationService()
    
    init() {
        // No es necesario establecer valores por defecto aquí ya que @AppStorage lo maneja
        // con los valores por defecto especificados (= true)
    }
    
    func resetToDefaults() {
        workDuration = Constants.Defaults.workDuration / 60
        shortBreakDuration = Constants.Defaults.shortBreakDuration / 60
        longBreakDuration = Constants.Defaults.longBreakDuration / 60
        sessionsUntilLongBreak = Constants.Defaults.sessionsUntilLongBreak
        isNotificationEnabled = true
        isSoundEnabled = true
    }
    
    // Verificar permisos de notificaciones al cambiar el toggle
    func toggleNotifications() async {
        if isNotificationEnabled {
            // Si el usuario activa las notificaciones, verificar permisos del sistema
            let hasPermission = await notificationService.checkNotificationPermissions()
            if !hasPermission {
                // Si no hay permisos, solicitar
                await notificationService.requestPermission()
            }
        }
    }
}
