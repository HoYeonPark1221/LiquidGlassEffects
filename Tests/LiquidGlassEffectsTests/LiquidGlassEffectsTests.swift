import AppKit
import SwiftUI
import XCTest
@testable import LiquidGlassEffects

@MainActor
final class LiquidGlassEffectsTests: XCTestCase {
    // MARK: - Names

    func testVariantRawValuesAreContiguous() {
        XCTAssertEqual(GlassVariant.allCases.map(\.rawValue), Array(0...23))
    }

    func testLabel() {
        XCTAssertEqual(GlassVariant.controlCenter.label, "ControlCenter")
    }

    func testOnlyFocusVariantsDrawNothingOnTheirOwn() {
        XCTAssertEqual(GlassVariant.allCases.filter { !$0.drawsOnItsOwn }, [.focusBorder, .focusPlatter])
    }

    func testSubvariantTableHasAllNamesOnce() {
        let names = GlassSubvariant.allCases.map(\.rawValue)
        XCTAssertEqual(names.count, 53)
        XCTAssertEqual(Set(names).count, 53)
        XCTAssertEqual(names.first, "default")
        XCTAssertEqual(names.last, "homeLiveActivity")
    }

    func testSubvariantAcceptsAnyName() {
        let literal: GlassSubvariant = "someNewName"
        XCTAssertEqual(literal.rawValue, "someNewName")
        XCTAssertEqual(GlassSubvariant(rawValue: "dock"), .dock)
        XCTAssertFalse(GlassSubvariant.allCases.contains(literal))
    }

    // MARK: - Bridge

    /// The real glass view. Older systems skip; on macOS 26+ a missing class is a failure,
    /// because that is exactly the breakage these tests exist to catch.
    private func makeGlass() throws -> NSView {
        if #unavailable(macOS 26) { throw XCTSkip("NSGlassEffectView needs macOS 26") }
        return try XCTUnwrap(GlassVariantBridge.makeGlassView(), "NSGlassEffectView is missing on macOS 26+")
    }

    /// A view without the private selectors must be left alone, not crash.
    func testApplyToPlainViewIsANoOp() {
        let view = NSView()
        XCTAssertFalse(GlassVariantBridge.apply(.bubbles, to: view))
        XCTAssertFalse(GlassVariantBridge.apply(.lockscreenControls, to: view))
        XCTAssertFalse(GlassVariantBridge.apply(tint: .red, to: view))
        XCTAssertFalse(GlassVariantBridge.setInteractive(true, on: view))
        XCTAssertFalse(GlassVariantBridge.setPath(CGPath(rect: .zero, transform: nil), on: view))
        XCTAssertNil(GlassVariantBridge.variant(of: view))
        XCTAssertNil(GlassVariantBridge.subvariant(of: view))
    }

    /// Round-trips every variant through the real private view.
    func testRoundTripOnRealGlassView() throws {
        let glass = try makeGlass()
        for variant in GlassVariant.allCases {
            XCTAssertTrue(GlassVariantBridge.apply(variant, to: glass), "setter missing for \(variant)")
            XCTAssertEqual(GlassVariantBridge.variant(of: glass), variant)
        }
    }

    func testSubvariantRoundTripOnRealGlassView() throws {
        let glass = try makeGlass()
        for subvariant in GlassSubvariant.allCases {
            XCTAssertTrue(GlassVariantBridge.apply(subvariant, to: glass), "setter missing for \(subvariant)")
            XCTAssertEqual(GlassVariantBridge.subvariant(of: glass), subvariant)
        }
    }

    func testPublicPropertiesOnRealGlassView() throws {
        let glass = try makeGlass()

        XCTAssertTrue(GlassVariantBridge.apply(tint: .systemBlue, to: glass))
        XCTAssertEqual(glass.value(forKey: "tintColor") as? NSColor, .systemBlue)

        XCTAssertTrue(GlassVariantBridge.setCornerRadius(21, on: glass))
        XCTAssertEqual(glass.value(forKey: "cornerRadius") as? CGFloat, 21)

        let content = NSView()
        XCTAssertTrue(GlassVariantBridge.setContentView(content, on: glass))
        XCTAssertTrue(glass.value(forKey: "contentView") as AnyObject === content)

        // `effectIsInteractive` exists from macOS 27; older systems skip it.
        if glass.responds(to: NSSelectorFromString("effectIsInteractive")) {
            XCTAssertTrue(GlassVariantBridge.setInteractive(true, on: glass))
            XCTAssertEqual(glass.value(forKey: "effectIsInteractive") as? Bool, true)
        }
    }

    func testPathOnRealGlassView() throws {
        let glass = try makeGlass()
        XCTAssertTrue(GlassVariantBridge.setPath(CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 80, height: 40), transform: nil), on: glass))
        XCTAssertTrue(GlassVariantBridge.setPath(nil, on: glass))
    }

    // MARK: - Shapes

    func testOutlineResolution() {
        XCTAssertEqual(GlassOutline.resolving(Capsule()).0, .capsule)
        XCTAssertEqual(GlassOutline.resolving(Rectangle()).0, .cornerRadius(0))
        XCTAssertEqual(GlassOutline.resolving(RoundedRectangle(cornerRadius: 12, style: .continuous)).0, .cornerRadius(12))
        XCTAssertEqual(GlassOutline.resolving(Circle()).0, .path)
        XCTAssertEqual(GlassOutline.resolving(RoundedRectangle(cornerSize: CGSize(width: 8, height: 4))).0, .path)
        XCTAssertNil(GlassOutline.resolving(Capsule()).1)
        XCTAssertNotNil(GlassOutline.resolving(Circle()).1)
    }

    // MARK: - Host view

    func testHostViewAppliesConfigurationAndSurvivesShapeChanges() throws {
        let host = GlassHostView(content: Text("Hello").padding())
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        host.frame = NSRect(x: 0, y: 0, width: 200, height: 100)

        func configuration(_ outline: GlassOutline) -> GlassConfiguration {
            GlassConfiguration(variant: .dock, subvariant: .menu, tint: nil, isInteractive: false, outline: outline)
        }

        host.update(content: Text("Hello").padding(), configuration: configuration(.cornerRadius(12)), customPath: nil)
        host.layoutSubtreeIfNeeded()
        if GlassVariantBridge.isAvailable {
            XCTAssertEqual(GlassVariantBridge.variant(of: host.glass), .dock)
            XCTAssertEqual(GlassVariantBridge.subvariant(of: host.glass), .menu)
        }

        // corner radius -> arbitrary path -> capsule -> corner radius again
        host.update(content: Text("Hello").padding(), configuration: configuration(.path), customPath: { Circle().path(in: $0) })
        host.layoutSubtreeIfNeeded()
        host.update(content: Text("Hello").padding(), configuration: configuration(.capsule), customPath: nil)
        host.layoutSubtreeIfNeeded()
        host.update(content: Text("Hello").padding(), configuration: configuration(.cornerRadius(4)), customPath: nil)
        host.layoutSubtreeIfNeeded()
    }

    func testHostViewSizesItselfFromContent() {
        let host = GlassHostView(content: Text("Hello, glass").padding(20))
        let ideal = host.sizeThatFits(.unspecified)
        XCTAssertGreaterThan(ideal.width, 40)
        XCTAssertLessThan(ideal.width, 400)

        let proposed = host.sizeThatFits(ProposedViewSize(width: 500, height: 300))
        XCTAssertLessThanOrEqual(proposed.width, 500)
        XCTAssertLessThanOrEqual(proposed.height, 300)
    }
}
