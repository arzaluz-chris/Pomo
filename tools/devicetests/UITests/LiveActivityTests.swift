// Drives the installed Pomo (Debug build) and the Dynamic Island on a real iPhone.
// Pomo must be a Debug build: it reads -PomoDebugAction to start a session at launch.
import XCTest

@MainActor
final class LiveActivityTests: XCTestCase {
    let pomo = XCUIApplication(bundleIdentifier: "com.christian-arzaluz.Pomo")
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUp() async throws { continueAfterFailure = true }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func dump(_ name: String) {
        let a = XCTAttachment(string: springboard.debugDescription)
        a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Long-press the Dynamic Island to expand the Live Activity.
    private func expandIsland() {
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.025)).press(forDuration: 1.2)
        sleep(2)
    }

    /// Tap an empty spot to collapse the expanded island.
    private func collapseIsland() {
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)).tap()
        sleep(1)
    }

    /// Break ends with the app killed; the island shows the end state; "Next" starts focus without opening the app.
    func testBreakEndsAndNextStartsFocus() throws {
        let minutes = Int(ProcessInfo.processInfo.environment["POMO_BREAK_MINUTES"] ?? "1") ?? 1
        pomo.launchArguments = ["-PomoDebugAction", "startBreak", "-shortBreakDuration", "\(minutes)"]
        pomo.launch()
        sleep(3)
        pomo.terminate()                       // app killed: only the system shows the activity now
        XCUIDevice.shared.press(.home)
        sleep(2)

        expandIsland()
        shot("1-expanded-running"); dump("1-springboard-running")
        collapseIsland()

        sleep(UInt32(minutes * 60 + 5))        // past the end
        shot("2-compact-ended")

        expandIsland()
        shot("3-expanded-ended"); dump("3-springboard-ended")
        let next = springboard.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 3), "Next button not found in expanded island")
        if next.exists { next.tap() }
        sleep(4)
        shot("4-after-next")

        expandIsland()
        shot("5-expanded-focus"); dump("5-springboard-focus")
        XCTAssertTrue(springboard.buttons["Pause"].waitForExistence(timeout: 3), "Focus session not running after Next")
        collapseIsland()
    }
}
