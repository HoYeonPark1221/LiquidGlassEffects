import SwiftUI
import AppKit

/// Embeds SwiftUI content in the private liquid-glass material.
///
/// ```swift
/// LiquidGlassBackground(variant: .bubbles, cornerRadius: 16) {
///     Text("Hello, glass!").padding()
/// }
/// ```
///
/// Where the private view is missing the content sits on an `NSVisualEffectView` blur instead.
/// Glass refracts what is behind it, so put it over something with detail — over a flat colour
/// every variant looks like the same translucent panel.
public struct LiquidGlassBackground<Content: View>: NSViewRepresentable {
    private let content: Content
    private let cornerRadius: CGFloat
    private let variant: GlassVariant
    private let subvariant: GlassSubvariant?

    public init(
        variant: GlassVariant = .bubbles,
        subvariant: GlassSubvariant? = nil,
        cornerRadius: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.subvariant = subvariant
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public func makeNSView(context: Context) -> NSView {
        let container = GlassVariantBridge.makeGlassView() ?? {
            let blur = NSVisualEffectView()
            blur.material = .underWindowBackground
            return blur
        }()

        let hosting = NSHostingView(rootView: content)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        configure(container)
        return container
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        if let hosting = nsView.subviews.compactMap({ $0 as? NSHostingView<Content> }).first {
            hosting.rootView = content
        }
        configure(nsView)
    }

    private func configure(_ view: NSView) {
        // Only the private glass view has these; the blur fallback has neither selector.
        guard view.responds(to: NSSelectorFromString("setCornerRadius:")) else { return }
        view.setValue(cornerRadius, forKey: "cornerRadius")
        GlassVariantBridge.apply(variant, to: view)
        if let subvariant {
            GlassVariantBridge.apply(subvariant, to: view)
        }
    }
}

public extension View {
    /// Puts private liquid glass behind this view.
    func privateGlassBackground(
        _ variant: GlassVariant = .bubbles,
        subvariant: GlassSubvariant? = nil,
        cornerRadius: CGFloat = 10
    ) -> some View {
        background {
            LiquidGlassBackground(variant: variant, subvariant: subvariant, cornerRadius: cornerRadius) {
                Color.clear
            }
            // The glass view draws refraction and shadow outside its own frame; clip it back.
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
