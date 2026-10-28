// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Orbit",
    platforms: [.macOS("14.2")],
    targets: [
        .executableTarget(name: "Orbit", path: "Sources/Orbit")
    ]
)
