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

    /// `false` for the two variants that draw nothing when used as a plain background
    /// (`focusBorder` and `focusPlatter`, observed on macOS 27.2).
    public var drawsOnItsOwn: Bool {
        self != .focusBorder && self != .focusPlatter
    }

    /// The case name with a capital first letter, e.g. `.controlCenter` -> "ControlCenter".
    public var label: String {
        let raw = String(describing: self)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}

/// A finer variant layered on top of a ``GlassVariant``.
///
/// A subvariant is a name. `DesignLibrary`'s `GlassMaterialProvider.Subvariant` is created from a
/// `String`, and on macOS 27.2 `set_subvariant:` takes an `NSString`. The 53 names here are the
/// ones in Apple's name table on that release, in table order; ``allCases`` lists them all.
///
/// Any string is accepted, so a name Apple adds later can be tried without a package update:
///
/// ```swift
/// .privateGlassBackground(.dock, subvariant: "someNewName")
/// ```
///
/// The setter accepts any string, so a successful `GlassVariantBridge.apply` means
/// "sent", not "recognised". Many names only change the glass slightly, and the ones aimed at
/// iOS or watchOS surfaces may render differently on macOS.
public struct GlassSubvariant: RawRepresentable, Hashable, Identifiable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible, CaseIterable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ name: String) {
        self.rawValue = name
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var id: String { rawValue }
    public var description: String { rawValue }

    public static let `default` = GlassSubvariant("default")
    public static let lockscreenControls = GlassSubvariant("lockscreenControls")
    public static let lockscreenNotifications = GlassSubvariant("lockscreenNotifications")
    public static let lockscreenPriorityNotifications = GlassSubvariant("lockscreenPriorityNotifications")
    public static let homescreenClose = GlassSubvariant("homescreenClose")
    public static let camera = GlassSubvariant("camera")
    public static let posterSwitcher = GlassSubvariant("posterSwitcher")
    public static let homescreenResizeHandle = GlassSubvariant("homescreenResizeHandle")
    public static let cursorAccessory = GlassSubvariant("cursorAccessory")
    public static let transientCanvas = GlassSubvariant("transientCanvas")
    public static let listening = GlassSubvariant("listening")
    public static let thinking = GlassSubvariant("thinking")
    public static let response = GlassSubvariant("response")
    public static let spotlightField = GlassSubvariant("spotlightField")
    public static let searchResults = GlassSubvariant("searchResults")
    public static let compose = GlassSubvariant("compose")
    public static let homescreenFolder = GlassSubvariant("homescreenFolder")
    public static let tab = GlassSubvariant("tab")
    public static let focusedButtonFill = GlassSubvariant("focusedButtonFill")
    public static let entryField = GlassSubvariant("entryField")
    public static let volumeSlider = GlassSubvariant("volumeSlider")
    public static let customizeSheet = GlassSubvariant("customizeSheet")
    public static let watchFacePhotos = GlassSubvariant("watchFacePhotos")
    public static let watchFacePhotosMini = GlassSubvariant("watchFacePhotosMini")
    public static let watchFaceFlowStencil = GlassSubvariant("watchFaceFlowStencil")
    public static let watchFaceFlowSolid = GlassSubvariant("watchFaceFlowSolid")
    public static let watchPasscode = GlassSubvariant("watchPasscode")
    public static let homescreenAppLibraryPod = GlassSubvariant("homescreenAppLibraryPod")
    public static let menu = GlassSubvariant("menu")
    public static let window = GlassSubvariant("window")
    public static let documentModalWindow = GlassSubvariant("documentModalWindow")
    public static let watchSmartStack = GlassSubvariant("watchSmartStack")
    public static let watchSmartStackFace = GlassSubvariant("watchSmartStackFace")
    public static let watchSmartStackAnimatedContent = GlassSubvariant("watchSmartStackAnimatedContent")
    public static let siriSnippet = GlassSubvariant("siriSnippet")
    public static let alarmSlider = GlassSubvariant("alarmSlider")
    public static let alarmSliderRed = GlassSubvariant("alarmSliderRed")
    public static let contactsQuickAction = GlassSubvariant("contactsQuickAction")
    public static let mapsSign = GlassSubvariant("mapsSign")
    public static let mapsNavigationSign = GlassSubvariant("mapsNavigationSign")
    public static let sheet = GlassSubvariant("sheet")
    public static let messagesTapback = GlassSubvariant("messagesTapback")
    public static let cluster = GlassSubvariant("cluster")
    public static let secondaryCluster = GlassSubvariant("secondaryCluster")
    public static let dock = GlassSubvariant("dock")
    public static let appSwitcher = GlassSubvariant("appSwitcher")
    public static let watchDetuned = GlassSubvariant("watchDetuned")
    public static let homeModularFace = GlassSubvariant("homeModularFace")
    public static let homeFaceFlow = GlassSubvariant("homeFaceFlow")
    public static let tvPortraitClock = GlassSubvariant("tvPortraitClock")
    public static let hdr = GlassSubvariant("hdr")
    public static let campoCard = GlassSubvariant("campoCard")
    public static let homeLiveActivity = GlassSubvariant("homeLiveActivity")

    /// Present in 0.1.0 but not in Apple's name table on macOS 27.2 (`tab` sits where it would be).
    @available(*, deprecated, message: "Not in Apple's name table on macOS 27.2; try .tab")
    public static let track = GlassSubvariant("track")

    /// Every name in Apple's table on macOS 27.2, in table order.
    public static let allCases: [GlassSubvariant] = [
        .`default`,
        .lockscreenControls,
        .lockscreenNotifications,
        .lockscreenPriorityNotifications,
        .homescreenClose,
        .camera,
        .posterSwitcher,
        .homescreenResizeHandle,
        .cursorAccessory,
        .transientCanvas,
        .listening,
        .thinking,
        .response,
        .spotlightField,
        .searchResults,
        .compose,
        .homescreenFolder,
        .tab,
        .focusedButtonFill,
        .entryField,
        .volumeSlider,
        .customizeSheet,
        .watchFacePhotos,
        .watchFacePhotosMini,
        .watchFaceFlowStencil,
        .watchFaceFlowSolid,
        .watchPasscode,
        .homescreenAppLibraryPod,
        .menu,
        .window,
        .documentModalWindow,
        .watchSmartStack,
        .watchSmartStackFace,
        .watchSmartStackAnimatedContent,
        .siriSnippet,
        .alarmSlider,
        .alarmSliderRed,
        .contactsQuickAction,
        .mapsSign,
        .mapsNavigationSign,
        .sheet,
        .messagesTapback,
        .cluster,
        .secondaryCluster,
        .dock,
        .appSwitcher,
        .watchDetuned,
        .homeModularFace,
        .homeFaceFlow,
        .tvPortraitClock,
        .hdr,
        .campoCard,
        .homeLiveActivity
    ]
}
