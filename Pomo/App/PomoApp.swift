// PomoApp.swift

import SwiftUI
import SwiftData
import UserNotifications

@main
struct PomoApp: App {
    let modelContainer: ModelContainer
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        do {
            let schema = Schema([TimerSession.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        // Configurar categorías de notificación
        NotificationService().setupNotificationCategories()
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

// AppDelegate para manejar notificaciones
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Manejar notificaciones cuando la app está en foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Mostrar notificación incluso si la app está abierta
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // Manejar acciones de notificación
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        switch response.actionIdentifier {
        case "START_WORK":
            // Notificar a la app para iniciar una sesión de trabajo
            NotificationCenter.default.post(name: .startWorkSession, object: nil)
        case "START_BREAK":
            // Notificar a la app para iniciar un descanso
            NotificationCenter.default.post(name: .startBreakSession, object: nil)
        case UNNotificationDefaultActionIdentifier:
            // El usuario tocó la notificación
            print("Usuario abrió la app desde la notificación")
        default:
            break
        }
        
        completionHandler()
    }
}

// Extensiones para notificaciones
extension Notification.Name {
    static let startWorkSession = Notification.Name("startWorkSession")
    static let startBreakSession = Notification.Name("startBreakSession")
}
