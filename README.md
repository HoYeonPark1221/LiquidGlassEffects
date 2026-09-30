# LiquidGlassEffects

SwiftUI access to the 24 Liquid Glass material variants (and 10 of the subvariants) inside AppKit's `NSGlassEffectView` — far more than the two (`.regular` / `.clear`) that the public `.glassEffect` API exposes.

![All 24 variants over the same detailed backdrop](Docs/gallery.png)

*All 24 variants over the same backdrop, from a demo app that is not part of this package. macOS 27.2, dark appearance, active window: glass renders differently in an inactive window.*

> ⚠️ **Private API.** `NSGlassEffectView` itself is public AppKit (macOS 26+), but its `_variant` / `_subvariant` properties are not. This package sets them through the Objective-C runtime. **Apps using it will likely be rejected from the Mac App Store.** It is meant for developer-ID / direct-distribution apps, internal tools and experiments. Apple can rename or remove these selectors in any macOS update.

## Safety model

- Nothing is linked at compile time; the class and selectors are looked up at runtime.
- Before an IMP is called, its type encoding is checked (an `NSInteger` or `NSString` argument, `void` return for setters). A renamed or re-typed selector is skipped instead of crashing.
- If anything is missing, calls are no-ops, getters return `nil`, and the view falls back to an `NSVisualEffectView` blur.
- `GlassVariantBridge.variant(of:)` reads the value back, so you can verify a variant actually applied.

## Usage

```swift
import LiquidGlassEffects

// A container
LiquidGlassBackground(variant: .bubbles, cornerRadius: 16) {
    Text("Hello, glass").padding()
}

// A background modifier
Text("Hello, glass")
    .padding()
    .privateGlassBackground(.avplayer, subvariant: .lockscreenControls, cornerRadius: 20)
```

Glass refracts what is behind it. Over a flat colour every variant looks the same, so judge them over a colourful or detailed backdrop. `GlassVariantGalleryView()` shows all 24 side by side:

```swift
GlassVariantGalleryView()
```

## Install

```swift
.package(url: "https://github.com/HoYeonPark1221/LiquidGlassEffects.git", from: "0.1.0")
```

Requires macOS 13+. The real glass needs a macOS that ships `NSGlassEffectView` (macOS 26+).

## Under the hood

### What is public, what is private

`NSGlassEffectView` is public AppKit (macOS 26+). Its public properties are `contentView`, `cornerRadius`, `tintColor`, `style` (`.regular` or `.clear`) and, from macOS 27, `effectIsInteractive`. The header:

```
/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/AppKit.framework/Headers/NSGlassEffectView.h
```

Behind `style`, the look of the glass is a *material* chosen by private properties. A **variant** is a whole preset (blur, refraction, highlights, tint). A **subvariant** is a name layered on top of it.

| Private selectors | Type | Used here | What it does |
|---|---|---|---|
| `_variant` / `set_variant:` | `NSInteger` | yes | Picks one of the 24 variants |
| `_subvariant` / `set_subvariant:` | `NSString` (macOS 27.2) | yes | Picks a subvariant by name |
| `_effectInteractiveVariantName` / `set_effectInteractiveVariantName:` | object | no | Unknown; the name suggests the variant used for interactive glass |

### The private framework

The names come from Apple's private `DesignLibrary` framework. On disk it is only a stub: the code lives in the dyld shared cache, and tools such as `dyld_info` resolve these paths from there.

```
/System/Library/PrivateFrameworks/DesignLibrary.framework
```

```
/System/Library/PrivateFrameworks/DesignLibrary.framework/DesignLibrary
```

The variants are the cases of `GlassMaterialProvider.Variant` in that framework. The subvariant names are plain strings that you only find in the shared cache (Apple silicon):

```
/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/
```

### The 24 variants

Apple does not document these. The last column is a guess from the name, plus what the demo screenshot shows.

| # | Variant | Name suggests |
|---|---|---|
| 0 | `regular` | standard glass |
| 1 | `clear` | clear glass |
| 2 | `dock` | the Dock |
| 3 | `appIcons` | app icons |
| 4 | `widgets` | widgets |
| 5 | `text` | text on glass |
| 6 | `avplayer` | media player; looks bright and glossy |
| 7 | `facetime` | FaceTime |
| 8 | `controlCenter` | Control Center |
| 9 | `notificationCenter` | notifications |
| 10 | `monogram` | monogram badge |
| 11 | `bubbles` | bubble; strong bright rim and refraction |
| 12 | `identity` | identity |
| 13 | `focusBorder` | focus ring border; draws nothing on its own |
| 14 | `focusPlatter` | focus platter; draws nothing on its own |
| 15 | `keyboard` | keyboard keys |
| 16 | `sidebar` | sidebar |
| 17 | `abuttedSidebar` | sidebar that abuts the content |
| 18 | `inspector` | inspector panel |
| 19 | `control` | controls |
| 20 | `loupe` | magnifier; nearly transparent with edge distortion |
| 21 | `slider` | slider |
| 22 | `camera` | camera UI |
| 23 | `cartouchePopover` | popover (a cartouche is an ornamental frame) |

### Subvariants

A subvariant is a name (a string) layered on top of a variant. `GlassSubvariant` has ten:

`default` · `lockscreenControls` · `homescreenClose` · `camera` · `posterSwitcher` · `homescreenResizeHandle` · `cursorAccessory` · `homescreenFolder` · `track` · `focusedButtonFill`

The names point at iOS and watchOS surfaces (lock screen, home screen, poster switcher). Setting a known name changes the rendered glass on macOS, sometimes only slightly (checked with screenshot diffs).

Apple's name table on macOS 27.2 is much longer: 53 names from `default` to `homeLiveActivity`, presumably the subvariant list. This package does not expose the rest yet. Nine of its ten names are in that table. `track` is not: `tab` sits at its position, so `.track` is unverified.

<details>
<summary>All 53 names in the table (macOS 27.2)</summary>

`default` · `lockscreenControls` · `lockscreenNotifications` · `lockscreenPriorityNotifications` · `homescreenClose` · `camera` · `posterSwitcher` · `homescreenResizeHandle` · `cursorAccessory` · `transientCanvas` · `listening` · `thinking` · `response` · `spotlightField` · `searchResults` · `compose` · `homescreenFolder` · `tab` · `focusedButtonFill` · `entryField` · `volumeSlider` · `customizeSheet` · `watchFacePhotos` · `watchFacePhotosMini` · `watchFaceFlowStencil` · `watchFaceFlowSolid` · `watchPasscode` · `homescreenAppLibraryPod` · `menu` · `window` · `documentModalWindow` · `watchSmartStack` · `watchSmartStackFace` · `watchSmartStackAnimatedContent` · `siriSnippet` · `alarmSlider` · `alarmSliderRed` · `contactsQuickAction` · `mapsSign` · `mapsNavigationSign` · `sheet` · `messagesTapback` · `cluster` · `secondaryCluster` · `dock` · `appSwitcher` · `watchDetuned` · `homeModularFace` · `homeFaceFlow` · `tvPortraitClock` · `hdr` · `campoCard` · `homeLiveActivity`

</details>

### Other things in the framework

Not used here. Most are Swift structs and enums, which the Objective-C runtime cannot call. Seen in the exported symbols: `GlassMaterialProvider` (with `Variant`, `Subvariant`, `Configuration` and `Options`), `RegularGlassMaterialProvider`, `ClearGlassMaterialProvider`, `GlassEdgeMaterialProvider`, `GlassGroupContext`, `WindowControl` (the window buttons, with their own variants), and drawing code for `Slider`, `Stepper`, `Switch`, `ProgressIndicator` and `ScrollPocket`.

## Explore it yourself

List the variant cases in declaration order. This is how the numbers in `GlassVariant` were checked:

```sh
xcrun dyld_info -exports /System/Library/PrivateFrameworks/DesignLibrary.framework/DesignLibrary | grep 'GlassMaterialProviderV7VariantO.*yA2EmFWC' | sort | sed -E 's/.*VariantO[0-9]+([A-Za-z]+)yA2EmFWC.*/\1/' | nl -v 0
```

Print the subvariant name table from the shared cache. `.05` is the piece that holds it on macOS 27.2; other builds may use another piece, and the start and end markers may move:

```sh
strings -a -n 3 /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e.05 | awk 'p=="unsupported" && $0=="default"{f=1} f{print} f && $0=="homeLiveActivity"{exit} {p=$0}'
```

## After a macOS update

```swift
#if DEBUG
GlassVariantBridge.dumpVariantSelectors()
#endif
```

prints the current variant-related selectors and their type encodings. Re-run the commands above to see whether Apple added or renamed variants and subvariants. `swift test` (via Xcode's toolchain) round-trips all 24 variants through the real view and fails if a setter disappeared.

## Verified on

macOS 27.2, with Xcode's toolchain:

- All 24 variants are set and read back through the real view. Their names and order match the case symbols exported by `DesignLibrary.framework`. Several render clearly differently (for example `bubbles`, `avplayer` and `loupe`); others look alike over a simple backdrop, and `focusBorder` / `focusPlatter` look empty as a plain background. Rendering also differs between an active and an inactive window.
- `set_subvariant:` takes an `NSString` on this system, so the bridge passes the case name. Nine of the ten names in `GlassSubvariant` are in Apple's name table; `track` is not (`tab` is). The setter accepts any string, so `apply` returning `true` means the call was made, not that the system recognised the name.

## Platform

macOS only. `NSGlassEffectView` is AppKit; iOS's `UIGlassEffect` is a different class with different knobs and is not covered.

## Disclaimer

Unofficial project. It is not affiliated with, endorsed by, or sponsored by Apple. Apple, macOS and other Apple names belong to their respective owners.

## License

MIT
