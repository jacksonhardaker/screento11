// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ScreenTo11",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "ScreenTo11", targets: ["ScreenTo11"])],
    targets: [
        .executableTarget(name: "ScreenTo11", path: "Sources/ScreenTo11"),
        .testTarget(name: "ScreenTo11Tests", dependencies: ["ScreenTo11"])
    ]
)
