// swift-tools-version: 5.9
import PackageDescription

// A playground for every variant. Run it with `swift run` from this folder.
let package = Package(
    name: "GlassLab",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "GlassLab",
            dependencies: [.product(name: "LiquidGlassEffects", package: "LiquidGlassEffects")]
        )
    ]
)
