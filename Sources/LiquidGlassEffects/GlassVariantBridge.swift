import AppKit
import ObjectiveC

/// Talks to `NSGlassEffectView`'s private `_variant` / `_subvariant` properties through the
/// Objective-C runtime.
///
/// Nothing here is linked at compile time. If a class or selector disappears in a future macOS,
/// every call silently does nothing (and getters return `nil`) — the glass just stays at the
/// system default. A private-API wrapper must fail quietly: an unchanged material is invisible
/// to users, a crash or a log flood is not.
///
/// Calling an IMP with the wrong signature crashes with `EXC_BAD_ACCESS`, so a selector's
/// existence is never trusted on its own: its type encoding is checked before every call.
public enum GlassVariantBridge {
    private typealias IntegerSetter = @convention(c) (AnyObject, Selector, Int) -> Void
    private typealias IntegerGetter = @convention(c) (AnyObject, Selector) -> Int
    private typealias ObjectSetter = @convention(c) (AnyObject, Selector, NSString?) -> Void
    private typealias ObjectGetter = @convention(c) (AnyObject, Selector) -> NSString?

    private static let variantSetters = ["set_variant:", "setVariant:"]
    private static let variantGetters = ["_variant", "variant"]
    private static let subvariantSetters = ["set_subvariant:", "setSubvariant:", "_setSubvariant:"]
    private static let subvariantGetters = ["_subvariant", "subvariant"]

    /// `true` when this system has `NSGlassEffectView`. Says nothing about whether the
    /// variant selectors still exist; use ``variant(of:)`` for that.
    public static var isAvailable: Bool {
        NSClassFromString("NSGlassEffectView") is NSView.Type
    }

    /// A new `NSGlassEffectView`, or `nil` if the class does not exist on this system.
    public static func makeGlassView() -> NSView? {
        guard let type = NSClassFromString("NSGlassEffectView") as? NSView.Type else { return nil }
        return type.init(frame: .zero)
    }

    /// Sets the main variant. Returns `true` if a matching setter was found and called.
    @discardableResult
    public static func apply(_ variant: GlassVariant, to object: AnyObject) -> Bool {
        setInteger(variant.rawValue, candidates: variantSetters, on: object)
    }

    /// Sets the subvariant. Returns `true` if a matching setter was found and called.
    ///
    /// Recent macOS takes the subvariant as a name string (`set_subvariant:` is `v@:@`); older
    /// builds took an integer. Both are tried. The string setter accepts any string, so `true`
    /// means "called", not "the system recognised the name".
    @discardableResult
    public static func apply(_ subvariant: GlassSubvariant, to object: AnyObject) -> Bool {
        setString(String(describing: subvariant), candidates: subvariantSetters, on: object)
            || setInteger(subvariant.rawValue, candidates: subvariantSetters, on: object)
    }

    /// The variant currently set on `object`, or `nil` if it cannot be read.
    public static func variant(of object: AnyObject) -> GlassVariant? {
        getInteger(candidates: variantGetters, from: object).flatMap(GlassVariant.init(rawValue:))
    }

    /// The subvariant currently set on `object`, or `nil` if it cannot be read.
    public static func subvariant(of object: AnyObject) -> GlassSubvariant? {
        if let name = getString(candidates: subvariantGetters, from: object) {
            return GlassSubvariant.allCases.first { String(describing: $0) == name }
        }
        return getInteger(candidates: subvariantGetters, from: object).flatMap(GlassSubvariant.init(rawValue:))
    }

    // MARK: - Runtime plumbing

    private static func setInteger(_ value: Int, candidates: [String], on object: AnyObject) -> Bool {
        let cls: AnyClass = object_getClass(object) ?? type(of: object)
        for name in candidates {
            let selector = NSSelectorFromString(name)
            guard let method = class_getInstanceMethod(cls, selector),
                  hasSignature(method, arguments: 3, returns: "v", integerArgument: true)
            else { continue }
            let setter = unsafeBitCast(method_getImplementation(method), to: IntegerSetter.self)
            setter(object, selector, value)
            return true
        }
        return false
    }

    private static func getInteger(candidates: [String], from object: AnyObject) -> Int? {
        let cls: AnyClass = object_getClass(object) ?? type(of: object)
        for name in candidates {
            let selector = NSSelectorFromString(name)
            guard let method = class_getInstanceMethod(cls, selector),
                  hasSignature(method, arguments: 2, returns: nil, integerArgument: false)
            else { continue }
            let getter = unsafeBitCast(method_getImplementation(method), to: IntegerGetter.self)
            return getter(object, selector)
        }
        return nil
    }

    private static func setString(_ value: String, candidates: [String], on object: AnyObject) -> Bool {
        let cls: AnyClass = object_getClass(object) ?? type(of: object)
        for name in candidates {
            let selector = NSSelectorFromString(name)
            guard let method = class_getInstanceMethod(cls, selector),
                  method_getNumberOfArguments(method) == 3,
                  encoding(ofReturn: method) == "v",
                  encoding(ofArgument: 2, of: method) == "@"
            else { continue }
            let setter = unsafeBitCast(method_getImplementation(method), to: ObjectSetter.self)
            setter(object, selector, value as NSString)
            return true
        }
        return false
    }

    private static func getString(candidates: [String], from object: AnyObject) -> String? {
        let cls: AnyClass = object_getClass(object) ?? type(of: object)
        for name in candidates {
            let selector = NSSelectorFromString(name)
            guard let method = class_getInstanceMethod(cls, selector),
                  method_getNumberOfArguments(method) == 2,
                  encoding(ofReturn: method) == "@"
            else { continue }
            let getter = unsafeBitCast(method_getImplementation(method), to: ObjectGetter.self)
            return getter(object, selector) as String?
        }
        return nil
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

    /// Checks the type encoding against `(self, _cmd[, integer]) -> void | integer`.
    private static func hasSignature(
        _ method: Method,
        arguments: Int,
        returns expectedReturn: String?,
        integerArgument: Bool
    ) -> Bool {
        guard method_getNumberOfArguments(method) == UInt32(arguments) else { return false }

        let returnType = method_copyReturnType(method)
        defer { free(returnType) }
        let returned = String(cString: returnType)
        if let expectedReturn {
            guard returned == expectedReturn else { return false }
        } else {
            guard isIntegerEncoding(returned) else { return false }
        }

        guard integerArgument else { return true }
        guard let argType = method_copyArgumentType(method, 2) else { return false }
        defer { free(argType) }
        return isIntegerEncoding(String(cString: argType))
    }

    /// Only 64-bit integers (`NSInteger` is `q`) are accepted. Narrower encodings are rejected
    /// so an IMP call can never read or write the wrong register width.
    private static func isIntegerEncoding(_ encoding: String) -> Bool {
        encoding == "q" || encoding == "Q"
    }

    #if DEBUG
    /// Prints every `variant`-related selector of `NSGlassEffectView` with its type encoding.
    /// Handy after an OS update to see what Apple renamed.
    public static func dumpVariantSelectors() {
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
            guard name.lowercased().contains("variant") else { continue }
            let encoding = method_getTypeEncoding(method).map { String(cString: $0) } ?? "?"
            print("[LiquidGlassEffects] \(name) [\(encoding)] args=\(method_getNumberOfArguments(method))")
        }
    }
    #endif
}
