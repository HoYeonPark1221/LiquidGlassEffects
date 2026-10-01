import LiquidGlassEffects
import Observation
import SwiftUI

enum ShapeChoice: String, CaseIterable, Identifiable {
    case roundedRectangle = "Rounded"
    case capsule = "Capsule"
    case circle = "Circle"
    case star = "Star"
    case hexagon = "Hexagon"

    var id: String { rawValue }
}

enum BackdropChoice: String, CaseIterable, Identifiable {
    case scene = "Scene"
    case gradient = "Gradient"
    case stripes = "Stripes"
    case image = "Your image"

    var id: String { rawValue }
}

@Observable
final class LabModel {
    var variant: GlassVariant = .bubbles
    var subvariant: GlassSubvariant?
    var shape: ShapeChoice = .roundedRectangle
    var cornerRadius: Double = 28
    var width: Double = 300
    var height: Double = 150
    var usesTint = false
    var tint: Color = .blue
    var isInteractive = false
    var backdrop: BackdropChoice = .scene
    var customImage: NSImage?
    var showsGallery = ProcessInfo.processInfo.environment["GLASSLAB_START"] == "gallery"

    /// The Swift you would write to get what is on screen.
    var code: String {
        var arguments = [".\(variant)"]
        if let subvariant { arguments.append("subvariant: \(subvariant.isInTable ? "." : "")\(subvariant.rawValue.escapedForSwift)") }
        switch shape {
        case .roundedRectangle: arguments.append("cornerRadius: \(Int(cornerRadius))")
        case .capsule: arguments.append("in: Capsule()")
        case .circle: arguments.append("in: Circle()")
        case .star: arguments.append("in: Star()")
        case .hexagon: arguments.append("in: Hexagon()")
        }
        if usesTint { arguments.append("tint: .blue") }
        if isInteractive { arguments.append("isInteractive: true") }
        return """
        Text("Hello, glass")
            .padding(32)
            .privateGlassBackground(\(arguments.joined(separator: ", ")))
        """
    }
}

private extension GlassSubvariant {
    var isInTable: Bool { Self.allCases.contains(self) }
}

private extension String {
    /// `default` is a keyword, so the static member needs backticks.
    var escapedForSwift: String { self == "default" ? "`default`" : self }
}
