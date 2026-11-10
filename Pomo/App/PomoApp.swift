// PomoApp.swift

import SwiftUI
import SwiftData
import WatchConnectivity

@main
struct PomoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    // Owned by the app (not by a view) so it exists even when the system launches the
    // process in the background to run a Live Activity intent, with no UI.
    let timerViewModel: TimerViewModel

    init() {
        // Defaults for settings that must be on before the Settings tab is ever opened
        UserDefaults.standard.register(defaults: [
            Constants.UserDefaults.isNotificationEnabled: true,
            Constants.UserDefaults.isSoundEnabled: true
        ])

        do {
            let schema = Schema([TimerSession.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        #if DEBUG
        DemoData.seed(into: modelContainer)
        #endif

        // Activate WatchConnectivity for iPhone <-> Watch sync
        WatchConnectivityManager.shared.activate()

        let timerViewModel = TimerViewModel(modelContainer: modelContainer)
        self.timerViewModel = timerViewModel
        PomoTimerActionDispatcher.handler = { action in
            await timerViewModel.perform(action)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
            .environmentObject(timerViewModel)
        }
        .modelContainer(modelContainer)
    }
}

// AppDelegate para configurar el SceneDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}
