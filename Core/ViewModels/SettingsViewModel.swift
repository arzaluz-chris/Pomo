// SettingsViewModel.swift

import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage(Constants.UserDefaults.workDuration) var workDuration: Int = Constants.Defaults.workDuration / 60 {
        didSet { syncSettingsToWatch() }
    }
    @AppStorage(Constants.UserDefaults.shortBreakDuration) var shortBreakDuration: Int = Constants.Defaults.shortBreakDuration / 60 {
        didSet { syncSettingsToWatch() }
    }
    @AppStorage(Constants.UserDefaults.longBreakDuration) var longBreakDuration: Int = Constants.Defaults.longBreakDuration / 60 {
        didSet { syncSettingsToWatch() }
    }
    @AppStorage(Constants.UserDefaults.sessionsUntilLongBreak) var sessionsUntilLongBreak: Int = Constants.Defaults.sessionsUntilLongBreak {
        didSet { syncSettingsToWatch() }
    }
    @AppStorage(Constants.UserDefaults.isNotificationEnabled) var isNotificationEnabled: Bool = true
    @AppStorage(Constants.UserDefaults.isSoundEnabled) var isSoundEnabled: Bool = true

    init() {
        // Establecer valores por defecto si es la primera vez
        if UserDefaults.standard.object(forKey: Constants.UserDefaults.isNotificationEnabled) == nil {
            UserDefaults.standard.set(true, forKey: Constants.UserDefaults.isNotificationEnabled)
        }
        if UserDefaults.standard.object(forKey: Constants.UserDefaults.isSoundEnabled) == nil {
            UserDefaults.standard.set(true, forKey: Constants.UserDefaults.isSoundEnabled)
        }
    }

    func resetToDefaults() {
        workDuration = Constants.Defaults.workDuration / 60
        shortBreakDuration = Constants.Defaults.shortBreakDuration / 60
        longBreakDuration = Constants.Defaults.longBreakDuration / 60
        sessionsUntilLongBreak = Constants.Defaults.sessionsUntilLongBreak
        isNotificationEnabled = true
        isSoundEnabled = true
    }

    private func syncSettingsToWatch() {
        let settings = SettingsSync(
            workDuration: workDuration,
            shortBreakDuration: shortBreakDuration,
            longBreakDuration: longBreakDuration,
            sessionsUntilLongBreak: sessionsUntilLongBreak
        )
        WatchConnectivityManager.shared.syncSettings(settings)
    }
}
