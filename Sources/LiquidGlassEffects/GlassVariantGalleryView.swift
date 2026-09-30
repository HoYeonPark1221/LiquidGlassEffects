import SwiftUI

/// Shows all 24 variants side by side over a busy backdrop, for comparing them by eye.
public struct GlassVariantGalleryView: View {
    private let columns = [GridItem(.adaptive(minimum: 132, maximum: 132), spacing: 16)]

    public init() {}

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 22) {
                ForEach(GlassVariant.allCases) { variant in
                    VStack(spacing: 8) {
                        Color.clear
                            .frame(width: 132, height: 44)
                            .privateGlassBackground(variant, cornerRadius: 12)
                        VStack(spacing: 1) {
                            Text(variant.label).font(.system(size: 11, weight: .semibold))
                            Text("#\(variant.rawValue)").font(.system(size: 9)).opacity(0.7)
                        }
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 3)
                    }
                }
            }
            .padding(24)
        }
        .background(backdrop)
        .frame(minWidth: 640, minHeight: 560)
    }

    private var backdrop: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [.yellow, .clear], center: .topLeading, startRadius: 4, endRadius: 260)
            RadialGradient(colors: [.mint, .clear], center: .bottomTrailing, startRadius: 4, endRadius: 300)
            RadialGradient(colors: [.cyan, .clear], center: .topTrailing, startRadius: 4, endRadius: 260)
            RadialGradient(colors: [.red, .clear], center: .bottomLeading, startRadius: 4, endRadius: 240)
        }
        .ignoresSafeArea()
    }
}
