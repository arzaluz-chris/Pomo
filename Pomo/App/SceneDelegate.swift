// SceneDelegate.swift

import UIKit
import SwiftUI
import StoreKit

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    enum ActionType: String {
        case startWork = "StartWorkAction"
        case startBreak = "StartBreakAction"
        case viewStats = "ViewStatsAction"
        case rateApp = "RateAppAction"
    }
    
    @AppStorage("selectedTab") private var selectedTab = 0
    @AppStorage("shouldStartTimer") private var shouldStartTimer = false
    @AppStorage("quickActionTimerType") private var quickActionTimerType = ""
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Procesar quick action si el usuario seleccionó una para lanzar la app
        if let shortcutItem = connectionOptions.shortcutItem {
            handleShortcutItem(shortcutItem)
        }
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        let handled = handleShortcutItem(shortcutItem)
        completionHandler(handled)
    }
    
    @discardableResult
    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let actionType = ActionType(rawValue: shortcutItem.type) else {
            return false
        }
        
        switch actionType {
        case .startWork:
            // Navegar a la pestaña del timer y empezar sesión de trabajo
            selectedTab = 0
            quickActionTimerType = TimerType.work.rawValue
            shouldStartTimer = true
            return true
            
        case .startBreak:
            // Navegar a la pestaña del timer y empezar sesión de descanso
            selectedTab = 0
            quickActionTimerType = TimerType.shortBreak.rawValue
            shouldStartTimer = true
            return true
            
        case .viewStats:
            // Navegar a la pestaña de estadísticas
            selectedTab = 1
            return true
            
        case .rateApp:
            // Abrir App Store para calificar
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
            return true
        }
    }
}
