import AppKit
import ObjectiveC

/// Talks to `NSGlassEffectView` through the Objective-C runtime: the private `_variant` /
/// `_subvariant` / `_setPath:` selectors and a few public properties.
///
/// Nothing here is linked at compile time. If a class or selector disappears in a future macOS,
/// every call silently does nothing (and getters return `nil`) — the glass just stays at the
/// system default. A private-API wrapper must fail quietly: an unchanged material is invisible
/// to users, a crash or a log flood is not.
///
/// Calling an IMP with the wrong signature crashes with `EXC_BAD_ACCESS`, so a selector's
/// existence is never trusted on its own: its type encoding is checked before every call.
///
/// Every method returns `true` when a matching selector was found and called.
@MainActor
public enum GlassVariantBridge {
    private typealias IntegerSetter = @convention(c) (AnyObject, Selector, Int) -> Void
    private typealias IntegerGetter = @convention(c) (AnyObject, Selector) -> Int
    private typealias BoolSetter = @convention(c) (AnyObject, Selector, Bool) -> Void
    private typealias DoubleSetter = @convention(c) (AnyObject, Selector, Double) -> Void
    private typealias ObjectSetter = @convention(c) (AnyObject, Selector, AnyObject?) -> Void
    private typealias ObjectGetter = @convention(c) (AnyObject, Selector) -> AnyObject?
    private typealias PathSetter = @convention(c) (AnyObject, Selector, CGPath?) -> Void

    private static let variantSetters = ["set_variant:", "setVariant:"]
    private static let variantGetters = ["_variant", "variant"]
    private static let subvariantSetters = ["set_subvariant:", "setSubvariant:", "_setSubvariant:"]
    private static let subvariantGetters = ["_subvariant", "subvariant"]
    private static let tintSetters = ["setTintColor:"]
    private static let interactiveSetters = ["setEffectIsInteractive:", "set_effectIsInteractive:"]
    private static let cornerRadiusSetters = ["setCornerRadius:"]
    private static let contentViewSetters = ["setContentView:"]
    private static let pathSetters = ["_setPath:"]

    /// `true` when this system has `NSGlassEffectView`. Says nothing about whether the
    /// variant selectors still exist; use ``variant(of:)`` for that.
    public nonisolated static var isAvailable: Bool {
        NSClassFromString("NSGlassEffectView") is NSView.Type
    }

    /// A new `NSGlassEffectView`, or `nil` if the class does not exist on this system.
    public static func makeGlassView() -> NSView? {
        guard let type = NSClassFromString("NSGlassEffectView") as? NSView.Type else { return nil }
        return type.init(frame: .zero)
    }

    /// Sets the main variant.
    @discardableResult
    public static func apply(_ variant: GlassVariant, to object: AnyObject) -> Bool {
        set(.integer(variant.rawValue), candidates: variantSetters, on: object)
    }

    /// Sets the subvariant.
    ///
    /// Recent macOS takes the subvariant as a name string (`set_subvariant:` is `v@:@`). The
    /// setter accepts any string, so `true` means "called", not "the system recognised the name".
    @discardableResult
    public static func apply(_ subvariant: GlassSubvariant, to object: AnyObject) -> Bool {
        set(.object(subvariant.rawValue as NSString), candidates: subvariantSetters, on: object)
    }

    /// Sets the tint colour (`NSGlassEffectView.tintColor`, public). `nil` clears it.
    @discardableResult
    public static func apply(tint: NSColor?, to object: AnyObject) -> Bool {
        set(.object(tint), candidates: tintSetters, on: object)
    }

    /// Turns interactive glass on or off (`NSGlassEffectView.effectIsInteractive`, macOS 27+).
    @discardableResult
    public static func setInteractive(_ isInteractive: Bool, on object: AnyObject) -> Bool {
        set(.bool(isInteractive), candidates: interactiveSetters, on: object)
    }

    /// Sets the corner radius (`NSGlassEffectView.cornerRadius`, public).
    @discardableResult
    public static func setCornerRadius(_ radius: CGFloat, on object: AnyObject) -> Bool {
        set(.double(Double(radius)), candidates: cornerRadiusSetters, on: object)
    }

    /// Sets the view the glass wraps (`NSGlassEffectView.contentView`, public). Only the content
    /// view is guaranteed to sit inside the glass; other subviews have no defined z-order.
    @discardableResult
    public static func setContentView(_ view: NSView?, on object: AnyObject) -> Bool {
        set(.object(view), candidates: contentViewSetters, on: object)
    }

    /// Gives the glass an arbitrary outline (private `_setPath:`), in the view's own
    /// coordinates with the origin at the bottom left. `nil` goes back to the corner radius.
    @discardableResult
    public static func setPath(_ path: CGPath?, on object: AnyObject) -> Bool {
        set(.path(path), candidates: pathSetters, on: object)
    }

    /// The variant currently set on `object`, or `nil` if it cannot be read.
    public static func variant(of object: AnyObject) -> GlassVariant? {
        guard let value = integerValue(candidates: variantGetters, from: object) else { return nil }
        return GlassVariant(rawValue: value)
    }

    /// The subvariant currently set on `object`, or `nil` if it cannot be read.
    public static func subvariant(of object: AnyObject) -> GlassSubvariant? {
        guard let match = lookup(object, candidates: subvariantGetters, signature: .getter(returning: { $0 == "@" })) else { return nil }
        let getter = unsafeBitCast(match.implementation, to: ObjectGetter.self)
        guard let name = getter(object, match.selector) as? String else { return nil }
        return GlassSubvariant(rawValue: name)
    }

    // MARK: - Runtime plumbing

    /// What a selector must look like before it is called: `(self, _cmd[, argument]) -> returns`.
    private struct Signature {
        var argumentCount: UInt32
        var returns: (String) -> Bool
        var argument: ((String) -> Bool)?

        static func getter(returning accepts: @escaping (String) -> Bool) -> Signature {
            Signature(argumentCount: 2, returns: accepts, argument: nil)
        }
    }

    private enum Argument {
        case integer(Int)
        case bool(Bool)
        case double(Double)
        case object(AnyObject?)
        case path(CGPath?)

        var signature: Signature {
            Signature(argumentCount: 3, returns: { $0 == "v" }, argument: accepts)
        }

        /// Only 64-bit integers (`NSInteger` is `q`) are accepted. Narrower encodings are rejected
        /// so an IMP call can never read or write the wrong register width. `BOOL` is `B` on
        /// arm64 and `c` on Intel.
        private var accepts: (String) -> Bool {
            switch self {
            case .integer: { $0 == "q" || $0 == "Q" }
            case .bool: { $0 == "B" || $0 == "c" }
            case .double: { $0 == "d" }
            case .object: { $0 == "@" }
            case .path: { $0.hasSuffix("^{CGPath=}") }
            }
        }
    }

    private static func lookup(
        _ object: AnyObject,
        candidates: [String],
        signature: Signature
    ) -> (selector: Selector, implementation: IMP)? {
        let cls: AnyClass = object_getClass(object) ?? type(of: object)
        for name in candidates {
            let selector = NSSelectorFromString(name)
            guard let method = class_getInstanceMethod(cls, selector),
                  method_getNumberOfArguments(method) == signature.argumentCount,
                  signature.returns(encoding(ofReturn: method))
            else { continue }
            if let accepts = signature.argument {
                guard let argument = encoding(ofArgument: 2, of: method), accepts(argument) else { continue }
            }
            return (selector, method_getImplementation(method))
        }
        return nil
    }

    private static func set(_ argument: Argument, candidates: [String], on object: AnyObject) -> Bool {
        guard let (selector, implementation) = lookup(object, candidates: candidates, signature: argument.signature) else {
            return false
        }
        switch argument {
        case .integer(let value): unsafeBitCast(implementation, to: IntegerSetter.self)(object, selector, value)
        case .bool(let value): unsafeBitCast(implementation, to: BoolSetter.self)(object, selector, value)
        case .double(let value): unsafeBitCast(implementation, to: DoubleSetter.self)(object, selector, value)
        case .object(let value): unsafeBitCast(implementation, to: ObjectSetter.self)(object, selector, value)
        case .path(let value): unsafeBitCast(implementation, to: PathSetter.self)(object, selector, value)
        }
        return true
    }

    private static func integerValue(candidates: [String], from object: AnyObject) -> Int? {
        guard let match = lookup(object, candidates: candidates, signature: .getter(returning: { $0 == "q" || $0 == "Q" })) else { return nil }
        return unsafeBitCast(match.implementation, to: IntegerGetter.self)(object, match.selector)
    }

    private static func encoding(ofReturn method: Method) -> String {
        let type = method_copyReturnType(method)
        defer { free(type) }
        return String(cString: type)
    }

    private static func encoding(ofArgument index: UInt32, of method: Method) -> String? {
        guard let type = method_copyArgumentType(method, index) else { return nil }
        defer { free(type) }
        return String(cString: type)
    }

    #if DEBUG
    /// Prints every `variant`-related selector of `NSGlassEffectView` with its type encoding.
    /// Handy after an OS update to see what Apple renamed.
    public static func dumpVariantSelectors() {
        dumpSelectors { $0.lowercased().contains("variant") }
    }

    /// Prints every private (underscore-prefixed) selector of `NSGlassEffectView` with its type
    /// encoding. A starting point for finding new knobs after an OS update.
    public static func dumpPrivateSelectors() {
        dumpSelectors { $0.hasPrefix("_") || $0.hasPrefix("set_") }
    }

    private static func dumpSelectors(matching filter: (String) -> Bool) {
        guard let cls = NSClassFromString("NSGlassEffectView") else {
            print("[LiquidGlassEffects] NSGlassEffectView not found")
            return
        }
        var count: UInt32 = 0
        guard let methods = class_copyMethodList(cls, &count) else { return }
        defer { free(methods) }
        for index in 0..<Int(count) {
            let method = methods[index]
            let name = NSStringFromSelector(method_getName(method))
            guard filter(name) else { continue }
            let encoding = method_getTypeEncoding(method).map { String(cString: $0) } ?? "?"
            print("[LiquidGlassEffects] \(name) [\(encoding)] args=\(method_getNumberOfArguments(method))")
        }
    }
    #endif
}
