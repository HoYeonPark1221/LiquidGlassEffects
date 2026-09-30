import AppKit
import XCTest
@testable import LiquidGlassEffects

final class LiquidGlassEffectsTests: XCTestCase {
    func testVariantRawValuesAreContiguous() {
        XCTAssertEqual(GlassVariant.allCases.map(\.rawValue), Array(0...23))
        XCTAssertEqual(GlassSubvariant.allCases.map(\.rawValue), Array(0...9))
    }

    func testLabel() {
        XCTAssertEqual(GlassVariant.controlCenter.label, "ControlCenter")
    }

    /// A view without the private selectors must be left alone, not crash.
    func testApplyToPlainViewIsANoOp() {
        let view = NSView()
        XCTAssertFalse(GlassVariantBridge.apply(.bubbles, to: view))
        XCTAssertFalse(GlassVariantBridge.apply(.lockscreenControls, to: view))
        XCTAssertNil(GlassVariantBridge.variant(of: view))
    }

    /// Round-trips every variant through the real private view. Skipped where the class is gone.
    func testRoundTripOnRealGlassView() throws {
        let glass = try XCTUnwrap(GlassVariantBridge.makeGlassView(), "NSGlassEffectView unavailable")
        for variant in GlassVariant.allCases {
            XCTAssertTrue(GlassVariantBridge.apply(variant, to: glass), "setter missing for \(variant)")
            XCTAssertEqual(GlassVariantBridge.variant(of: glass), variant)
        }
    }

    func testSubvariantRoundTripOnRealGlassView() throws {
        let glass = try XCTUnwrap(GlassVariantBridge.makeGlassView(), "NSGlassEffectView unavailable")
        for subvariant in GlassSubvariant.allCases {
            XCTAssertTrue(GlassVariantBridge.apply(subvariant, to: glass), "setter missing for \(subvariant)")
            XCTAssertEqual(GlassVariantBridge.subvariant(of: glass), subvariant)
        }
    }
}
