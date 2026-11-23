// swift-tools-version: 5.9
// Unit tests for the shared Pomodoro engine (Shared/Engine), runnable without a
// simulator: `swift test --package-path PomoEngineTests`.
// Sources/PomoEngine contains symlinks to the files compiled into the app targets.
import PackageDescription

let package = Package(
    name: "PomoEngineTests",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PomoEngine", path: "Sources/PomoEngine"),
        .testTarget(name: "PomoEngineTests", dependencies: ["PomoEngine"], path: "Tests/PomoEngineTests"),
    ]
)
