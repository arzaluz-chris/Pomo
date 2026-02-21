// PomoWatch/App/PomoWatchApp.swift

import SwiftUI
import WatchConnectivity

@main
struct PomoWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchTimerView()
            }
        }
    }
}

class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        WatchConnectivityManager.shared.activate()
    }
}
