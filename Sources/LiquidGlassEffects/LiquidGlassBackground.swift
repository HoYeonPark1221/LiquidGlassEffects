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
/// Any `Shape` works, like `.glassEffect(in:)`:
///
/// ```swift
/// LiquidGlassBackground(variant: .dock, in: Capsule(), tint: .blue) {
///     Text("Hello, glass!").padding()
/// }
/// ```
///
/// Where the private view is missing the content sits on an `NSVisualEffectView` blur instead.
/// Glass refracts what is behind it, so put it over something with detail — over a flat colour
/// every variant looks like the same translucent panel.
public struct LiquidGlassBackground<Content: View>: NSViewRepresentable {
    private let content: Content
    private let configuration: GlassConfiguration
    private let customPath: ((CGRect) -> Path)?

    /// Glass with rounded corners.
    public init(
        variant: GlassVariant = .bubbles,
        subvariant: GlassSubvariant? = nil,
        cornerRadius: CGFloat = 10,
        tint: Color? = nil,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.configuration = GlassConfiguration(
            variant: variant,
            subvariant: subvariant,
            tint: tint.map { NSColor($0) },
            isInteractive: isInteractive,
            outline: .cornerRadius(cornerRadius)
        )
        self.customPath = nil
    }

    /// Glass in the outline of any `Shape`.
    ///
    /// `Rectangle`, `RoundedRectangle` and `Capsule` use the glass view's own corner radius.
    /// Everything else (`Circle`, `Ellipse`, your own shapes) goes through the private `_setPath:`.
    public init<S: Shape>(
        variant: GlassVariant = .bubbles,
        subvariant: GlassSubvariant? = nil,
        in shape: S,
        tint: Color? = nil,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        let (outline, path) = GlassOutline.resolving(shape)
        self.content = content()
        self.configuration = GlassConfiguration(
            variant: variant,
            subvariant: subvariant,
            tint: tint.map { NSColor($0) },
            isInteractive: isInteractive,
            outline: outline
        )
        self.customPath = path
    }

    public func makeNSView(context: Context) -> NSView {
        let view = GlassHostView(content: content)
        view.update(content: content, configuration: configuration, customPath: customPath)
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? GlassHostView<Content>)?.update(content: content, configuration: configuration, customPath: customPath)
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSView, context: Context) -> CGSize? {
        (nsView as? GlassHostView<Content>)?.sizeThatFits(proposal)
    }
}

public extension View {
    /// Puts private liquid glass behind this view.
    func privateGlassBackground(
        _ variant: GlassVariant = .bubbles,
        subvariant: GlassSubvariant? = nil,
        cornerRadius: CGFloat = 10,
        tint: Color? = nil,
        isInteractive: Bool = false
    ) -> some View {
        privateGlassBackground(
            variant,
            subvariant: subvariant,
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
            tint: tint,
            isInteractive: isInteractive
        )
    }

    /// Puts private liquid glass behind this view, in the outline of `shape`.
    func privateGlassBackground<S: Shape>(
        _ variant: GlassVariant = .bubbles,
        subvariant: GlassSubvariant? = nil,
        in shape: S,
        tint: Color? = nil,
        isInteractive: Bool = false
    ) -> some View {
        background {
            LiquidGlassBackground(variant: variant, subvariant: subvariant, in: shape, tint: tint, isInteractive: isInteractive) {
                Color.clear
            }
            // The glass view draws refraction and shadow outside its own frame; clip it back.
            .compositingGroup()
            .clipShape(shape)
            // A background should not swallow clicks meant for the view in front of it. Interactive
            // glass does its own event handling, so it keeps hit testing.
            .allowsHitTesting(isInteractive)
        }
    }
}

// MARK: - Internals

/// How the glass is outlined.
enum GlassOutline: Equatable {
    /// The glass view's own `cornerRadius`.
    case cornerRadius(CGFloat)
    /// Fully rounded ends: a corner radius of half the shorter side.
    case capsule
    /// Drawn through `_setPath:`; the path itself is kept apart because closures are not `Equatable`.
    case path

    /// The cheapest outline that reproduces `shape`, plus its path when it needs one.
    static func resolving<S: Shape>(_ shape: S) -> (GlassOutline, ((CGRect) -> Path)?) {
        switch shape {
        case is Capsule:
            return (.capsule, nil)
        case is Rectangle:
            return (.cornerRadius(0), nil)
        case let rounded as RoundedRectangle where rounded.cornerSize.width == rounded.cornerSize.height:
            return (.cornerRadius(rounded.cornerSize.width), nil)
        default:
            return (.path, { shape.path(in: $0) })
        }
    }
}

struct GlassConfiguration: Equatable {
    var variant: GlassVariant
    var subvariant: GlassSubvariant?
    var tint: NSColor?
    var isInteractive: Bool
    var outline: GlassOutline
}

/// Hosts the SwiftUI content inside `NSGlassEffectView.contentView`, or inside an
/// `NSVisualEffectView` when the glass class is missing. A hosting controller rather than a
/// hosting view, because only the controller can size itself for a proposal on macOS 13.
@MainActor
final class GlassHostView<Content: View>: NSView {
    let glass: NSView
    private let controller: NSHostingController<Content>
    private var hosting: NSView { controller.view }
    private let isRealGlass: Bool
    private var configuration: GlassConfiguration?
    private var customPath: ((CGRect) -> Path)?
    private var hasAppliedPath = false

    init(content: Content) {
        if let view = GlassVariantBridge.makeGlassView() {
            glass = view
            isRealGlass = true
        } else {
            let blur = NSVisualEffectView()
            blur.material = .underWindowBackground
            blur.blendingMode = .behindWindow
            blur.state = .active
            blur.wantsLayer = true
            glass = blur
            isRealGlass = false
        }
        controller = NSHostingController(rootView: content)
        super.init(frame: .zero)

        addSubview(glass)
        if !(isRealGlass && GlassVariantBridge.setContentView(hosting, on: glass)) {
            hosting.frame = glass.bounds
            hosting.autoresizingMask = [.width, .height]
            glass.addSubview(hosting)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// An unspecified dimension means "ideal size", which the controller only reports as `fittingSize`.
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        let ideal = hosting.fittingSize
        return controller.sizeThatFits(in: CGSize(
            width: min(proposal.width ?? ideal.width, 100_000),
            height: min(proposal.height ?? ideal.height, 100_000)
        ))
    }

    override func layout() {
        super.layout()
        glass.frame = bounds
        applyOutline()
    }

    func update(content: Content, configuration new: GlassConfiguration, customPath: ((CGRect) -> Path)?) {
        controller.rootView = content
        self.customPath = customPath

        let old = configuration
        configuration = new

        if isRealGlass {
            if old?.variant != new.variant { GlassVariantBridge.apply(new.variant, to: glass) }
            if old?.subvariant != new.subvariant, let subvariant = new.subvariant {
                GlassVariantBridge.apply(subvariant, to: glass)
            }
            if old?.tint != new.tint { GlassVariantBridge.apply(tint: new.tint, to: glass) }
            if old?.isInteractive != new.isInteractive { GlassVariantBridge.setInteractive(new.isInteractive, on: glass) }
        }
        if old?.outline != new.outline || new.outline == .path { needsLayout = true }
    }

    private func applyOutline() {
        guard let outline = configuration?.outline else { return }
        let size = bounds.size

        switch outline {
        case .cornerRadius(let radius):
            clearPath()
            setCornerRadius(radius)
        case .capsule:
            clearPath()
            setCornerRadius(min(size.width, size.height) / 2)
        case .path:
            guard size.width > 0, size.height > 0, let customPath else { return }
            // SwiftUI paths grow downward, the glass view's coordinates grow upward.
            var flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
            let path = customPath(CGRect(origin: .zero, size: size)).cgPath.copy(using: &flip)
            setPath(path)
        }
    }

    private func setCornerRadius(_ radius: CGFloat) {
        if isRealGlass {
            GlassVariantBridge.setCornerRadius(radius, on: glass)
        } else {
            glass.layer?.cornerRadius = radius
            glass.layer?.masksToBounds = true
        }
    }

    private func setPath(_ path: CGPath?) {
        if isRealGlass {
            if GlassVariantBridge.setPath(path, on: glass) { hasAppliedPath = path != nil }
        } else {
            let mask = CAShapeLayer()
            mask.path = path
            glass.layer?.mask = mask
            hasAppliedPath = path != nil
        }
    }

    private func clearPath() {
        guard hasAppliedPath else { return }
        setPath(nil)
    }
}
