// PomoApp.swift

import SwiftUI
import SwiftData

@main
struct PomoApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([TimerSession.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                TimerView()
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
                
                StatisticsView()
                    .tabItem {
                        Label("Estadísticas", systemImage: "chart.bar.fill")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Ajustes", systemImage: "gear")
                    }
            }
            .tint(.pomoPrimary)
        }
        .modelContainer(modelContainer)
    }
}
