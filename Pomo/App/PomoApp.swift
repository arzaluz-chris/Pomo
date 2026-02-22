// PomoApp.swift

import SwiftUI
import SwiftData
import WatchConnectivity

@main
struct PomoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("selectedTab") private var selectedTab = 0

    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([TimerSession.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Activate WatchConnectivity for iPhone <-> Watch sync
        WatchConnectivityManager.shared.activate()
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                TimerView()
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
                    .tag(0)
                
                StatisticsView()
                    .tabItem {
                        Label("Estadísticas", systemImage: "chart.bar.fill")
                    }
                    .tag(1)
                
                SettingsView()
                    .tabItem {
                        Label("Ajustes", systemImage: "gear")
                    }
                    .tag(2)
            }
            .tint(.pomoPrimary)
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
