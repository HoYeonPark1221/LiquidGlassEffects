# LiquidGlassEffects

SwiftUI access to the 24 Liquid Glass material variants and 10 subvariants inside AppKit's `NSGlassEffectView` — far more than the two (`.regular` / `.clear`) that the public `.glassEffect` API exposes.

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

## After a macOS update

```swift
#if DEBUG
GlassVariantBridge.dumpVariantSelectors()
#endif
```

prints the current variant-related selectors and their type encodings. `swift test` (via Xcode's toolchain) round-trips all 24 variants through the real view and fails if a setter disappeared.

## Verified on

macOS 27.2, with Xcode's toolchain:

- All 24 variants are set and read back through the real view. Their names and order match the case symbols exported by `DesignLibrary.framework`. Several render clearly differently (for example `bubbles`, `avplayer` and `loupe`); others look alike over a simple backdrop, and `focusBorder` / `focusPlatter` look empty as a plain background. Rendering also differs between an active and an inactive window.
- `set_subvariant:` takes an `NSString` on this system, so the bridge passes the case name. Seven of the ten names (`lockscreenControls`, `homescreenClose`, `homescreenFolder`, `homescreenResizeHandle`, `posterSwitcher`, `cursorAccessory`, `focusedButtonFill`) were found as strings in the system frameworks; `default`, `camera` and `track` were not. The setter accepts any string, so `apply` returning `true` means the call was made, not that the system recognised the name. Changing the subvariant does change the rendered output (measured with a screenshot diff), sometimes only slightly.

## Platform

macOS only. `NSGlassEffectView` is AppKit; iOS's `UIGlassEffect` is a different class with different knobs and is not covered.

## Disclaimer

Unofficial project. It is not affiliated with, endorsed by, or sponsored by Apple. Apple, macOS and other Apple names belong to their respective owners.

## License

MIT
