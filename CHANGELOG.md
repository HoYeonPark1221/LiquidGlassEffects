# Changelog

## 0.2.0

### Added

- **Any `Shape`**: `privateGlassBackground(_:subvariant:in:)` and `LiquidGlassBackground(in:)`.
  `Rectangle`, `RoundedRectangle` and `Capsule` use the glass view's corner radius; other shapes
  go through the private `_setPath:`.
- **All 53 subvariant names** from Apple's table on macOS 27.2. `GlassSubvariant` is now a name,
  so any string works.
- `tint:` and `isInteractive:` on the modifier and the container.
- `GlassVariantBridge.apply(tint:to:)`, `setInteractive(_:on:)`, `setCornerRadius(_:on:)`,
  `setContentView(_:on:)`, `setPath(_:on:)` and, in DEBUG, `dumpPrivateSelectors()`.
- `GlassVariant.drawsOnItsOwn`.
- **GlassLab**, a playground app in `Examples/GlassLab`, and `Scripts/make-demo-app.sh` to build
  it as a `.app`.
- CI on macOS 26 and 15, a release workflow that attaches GlassLab, and Swift Package Index
  configuration.
- `Docs/Internals.md` with the other private knobs that were tried.

### Changed

- The container hands its content to `NSGlassEffectView.contentView`. The public header only
  guarantees that view's placement; before, the content was added as a plain subview.
- `LiquidGlassBackground` sizes itself from its content.
- `privateGlassBackground` no longer takes clicks meant for the view in front of it, unless the
  glass is interactive.
- `GlassVariantBridge` is `@MainActor`, because it creates and mutates AppKit views.
- The README is shorter; the reverse-engineering notes moved to `Docs/Internals.md`.

### Breaking

- `GlassSubvariant` is a struct, not an enum. Static members such as `.lockscreenControls` still
  work, `rawValue` is a `String`, and `switch` over its cases no longer compiles.
- `GlassSubvariant.track` is deprecated: it is not in Apple's name table (`tab` is).
- The integer fallback for `set_subvariant:` is gone. It was never seen to be needed, and its
  values were a guess.

## 0.1.0

Initial release: the 24 variants and 10 subvariants through `NSGlassEffectView`, a SwiftUI
container and background modifier, and a gallery view.
