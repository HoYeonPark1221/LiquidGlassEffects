// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LiquidGlassEffects",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "LiquidGlassEffects", targets: ["LiquidGlassEffects"])
    ],
    targets: [
        .target(name: "LiquidGlassEffects"),
        .testTarget(name: "LiquidGlassEffectsTests", dependencies: ["LiquidGlassEffects"])
    ]
)
