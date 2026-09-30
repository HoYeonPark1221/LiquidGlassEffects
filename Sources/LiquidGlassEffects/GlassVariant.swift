import Foundation

/// The 24 material variants of `NSGlassEffectView`.
///
/// Names come from `GlassMaterialProvider.Variant` in
/// `/System/Library/PrivateFrameworks/DesignLibrary.framework`. Raw values follow that enum's
/// case order, which is the order the private `_variant` property appears to use. What each one
/// looks like is undocumented, so the name is the only hint about its intended use.
public enum GlassVariant: Int, CaseIterable, Identifiable, Sendable {
    case regular = 0
    case clear = 1
    case dock = 2
    case appIcons = 3
    case widgets = 4
    case text = 5
    case avplayer = 6
    case facetime = 7
    case controlCenter = 8
    case notificationCenter = 9
    case monogram = 10
    case bubbles = 11
    case identity = 12
    case focusBorder = 13
    case focusPlatter = 14
    case keyboard = 15
    case sidebar = 16
    case abuttedSidebar = 17
    case inspector = 18
    case control = 19
    case loupe = 20
    case slider = 21
    case camera = 22
    case cartouchePopover = 23

    public var id: Int { rawValue }

    /// The case name with a capital first letter, e.g. `.controlCenter` -> "ControlCenter".
    public var label: String {
        let raw = String(describing: self)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}

/// A finer variant layered on top of a ``GlassVariant``.
///
/// Names are strings (`DesignLibrary`'s `GlassMaterialProvider.Subvariant` is created from a
/// `String`). On macOS 27.2 every case except `track` is in Apple's name table, which is longer
/// than this enum; `tab` sits where `track` would be, so `track` is unverified. On current macOS
/// `set_subvariant:` takes an `NSString`, so the bridge passes the case name. The raw value is
/// only used by the integer fallback. The setter accepts any string, so a successful `apply`
/// means "sent", not "recognised".
public enum GlassSubvariant: Int, CaseIterable, Identifiable, Sendable {
    case `default` = 0
    case lockscreenControls = 1
    case homescreenClose = 2
    case camera = 3
    case posterSwitcher = 4
    case homescreenResizeHandle = 5
    case cursorAccessory = 6
    case homescreenFolder = 7
    case track = 8
    case focusedButtonFill = 9

    public var id: Int { rawValue }
}
