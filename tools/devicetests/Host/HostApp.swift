// Empty host: the UI tests drive the installed Pomo app and SpringBoard, not this app.
import SwiftUI

@main
struct HostApp: App {
    var body: some Scene { WindowGroup { Text("Pomo device tests") } }
}
