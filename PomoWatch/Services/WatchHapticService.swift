// PomoWatch/Services/WatchHapticService.swift

import WatchKit

struct WatchHapticService {
    func playStart() {
        WKInterfaceDevice.current().play(.start)
    }

    func playStop() {
        WKInterfaceDevice.current().play(.stop)
    }

    func playSuccess() {
        WKInterfaceDevice.current().play(.success)
    }

    func playWarning() {
        WKInterfaceDevice.current().play(.notification)
    }

    func playClick() {
        WKInterfaceDevice.current().play(.click)
    }

    func playSessionComplete() {
        // Play a distinct haptic pattern for session completion
        WKInterfaceDevice.current().play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.success)
        }
    }
}
