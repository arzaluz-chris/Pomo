// Shared/Connectivity/WatchConnectivityManager.swift

import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // Callbacks for received data
    var onSettingsReceived: ((SettingsSync) -> Void)?
    var onTimerStateReceived: ((TimerStateSync) -> Void)?
    var onSessionReceived: ((SessionSync) -> Void)?

    private var session: WCSession?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else {
            print("[WC] WCSession not supported on this device")
            return
        }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        print("[WC] WCSession activating...")
    }

    // MARK: - Send Settings (updateApplicationContext - latest wins)

    func syncSettings(_ settings: SettingsSync) {
        guard let session = session, session.activationState == .activated else {
            print("[WC] Session not activated, cannot sync settings")
            return
        }

        do {
            // Merge with existing context to preserve other keys
            var context = session.applicationContext
            let data = try JSONEncoder().encode(settings)
            context[Constants.WatchConnectivity.settingsKey] = data
            try session.updateApplicationContext(context)
            print("[WC] Settings synced via applicationContext")
        } catch {
            print("[WC] Error syncing settings: \(error)")
        }
    }

    // MARK: - Send Timer State (applicationContext + sendMessage for real-time)

    func syncTimerState(_ state: TimerStateSync) {
        guard let session = session, session.activationState == .activated else {
            print("[WC] Session not activated, cannot sync timer state")
            return
        }

        do {
            // Always update application context (guaranteed delivery)
            var context = session.applicationContext
            let data = try JSONEncoder().encode(state)
            context[Constants.WatchConnectivity.timerStateKey] = data
            try session.updateApplicationContext(context)

            // Also send real-time message if reachable
            if session.isReachable {
                session.sendMessage(state.toDictionary(), replyHandler: nil) { error in
                    print("[WC] Error sending timer state message: \(error)")
                }
            }
        } catch {
            print("[WC] Error syncing timer state: \(error)")
        }
    }

    // MARK: - Send Completed Session (transferUserInfo - guaranteed queued delivery)

    func syncCompletedSession(_ sessionSync: SessionSync) {
        guard let session = session, session.activationState == .activated else {
            print("[WC] Session not activated, cannot sync session")
            return
        }

        session.transferUserInfo(sessionSync.toDictionary())
        print("[WC] Completed session queued via transferUserInfo")
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("[WC] Activation failed: \(error)")
        } else {
            print("[WC] Activation completed: \(activationState.rawValue)")
        }
    }

    // MARK: iOS-only delegate methods
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[WC] Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("[WC] Session deactivated, reactivating...")
        session.activate()
    }
    #endif

    // MARK: - Receive Application Context

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("[WC] Received applicationContext")

        if let settings = SettingsSync.from(dictionary: applicationContext) {
            DispatchQueue.main.async { [weak self] in
                self?.onSettingsReceived?(settings)
            }
        }

        if let timerState = TimerStateSync.from(dictionary: applicationContext) {
            DispatchQueue.main.async { [weak self] in
                self?.onTimerStateReceived?(timerState)
            }
        }
    }

    // MARK: - Receive Real-time Message

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("[WC] Received real-time message")

        if let timerState = TimerStateSync.from(dictionary: message) {
            DispatchQueue.main.async { [weak self] in
                self?.onTimerStateReceived?(timerState)
            }
        }
    }

    // MARK: - Receive User Info (queued completed sessions)

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        print("[WC] Received userInfo")

        if let sessionSync = SessionSync.from(dictionary: userInfo) {
            DispatchQueue.main.async { [weak self] in
                self?.onSessionReceived?(sessionSync)
            }
        }
    }
}
