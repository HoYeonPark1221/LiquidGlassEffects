import SwiftUI

/// Glass refracts what is behind it, so every backdrop here has sharp edges and bright colour.
struct BackdropView: View {
    let choice: BackdropChoice
    let image: NSImage?

    var body: some View {
        switch choice {
        case .scene: SceneBackdrop()
        case .gradient: GradientBackdrop()
        case .stripes: StripesBackdrop()
        case .image:
            if let image {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                SceneBackdrop().overlay(alignment: .bottom) {
                    Text("Choose an image in the inspector, or drop one here")
                        .font(.callout.weight(.medium))
                        .padding(8)
                        .background(.black.opacity(0.5), in: Capsule())
                        .foregroundStyle(.white)
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

struct SceneBackdrop: View {
    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [Color(red: 0.07, green: 0.05, blue: 0.30), .purple, .pink, .orange, .yellow]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height * 0.78)
                )
            )

            let sun = CGRect(x: size.width * 0.62, y: size.height * 0.30, width: size.height * 0.34, height: size.height * 0.34)
            context.fill(Path(ellipseIn: sun), with: .color(.white))

            for (index, tone) in [0.30, 0.20, 0.12].enumerated() {
                var ridge = Path()
                let base = size.height * (0.62 + 0.10 * Double(index))
                ridge.move(to: CGPoint(x: 0, y: size.height))
                for step in 0...40 {
                    let x = size.width * Double(step) / 40
                    let y = base - sin(Double(step) * 0.55 + Double(index) * 1.7) * size.height * 0.07
                        - sin(Double(step) * 1.3 + Double(index)) * size.height * 0.03
                    ridge.addLine(to: CGPoint(x: x, y: y))
                }
                ridge.addLine(to: CGPoint(x: size.width, y: size.height))
                ridge.closeSubpath()
                context.fill(ridge, with: .color(Color(red: tone * 0.5, green: tone * 0.2, blue: tone)))
            }

            for index in 0..<7 {
                let y = size.height * (0.10 + 0.07 * Double(index))
                let width = size.width * (0.18 + 0.05 * Double(index % 3))
                context.fill(Path(roundedRect: CGRect(x: size.width * 0.06, y: y, width: width, height: 8), cornerRadius: 4), with: .color(.white.opacity(0.9)))
            }

            let title = context.resolve(Text("REFRACTION").font(.system(size: size.height * 0.2, weight: .black)).foregroundColor(.black))
            context.draw(title, at: CGPoint(x: size.width * 0.5, y: size.height * 0.5))
        }
    }
}

struct GradientBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [.yellow, .clear], center: .topLeading, startRadius: 4, endRadius: 360)
            RadialGradient(colors: [.mint, .clear], center: .bottomTrailing, startRadius: 4, endRadius: 400)
            RadialGradient(colors: [.cyan, .clear], center: .topTrailing, startRadius: 4, endRadius: 360)
            RadialGradient(colors: [.red, .clear], center: .bottomLeading, startRadius: 4, endRadius: 340)
        }
    }
}

struct StripesBackdrop: View {
    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(Gradient(colors: [.indigo, .purple, .pink, .orange]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height))
            )
            var y = 8.0
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 6)), with: .color(.white.opacity(0.85)))
                y += 26
            }
            for index in 0..<8 {
                let text = context.resolve(Text("GLASS REFRACTION \(index)").font(.system(size: 54, weight: .black)).foregroundColor(.black))
                context.draw(text, at: CGPoint(x: size.width * 0.35, y: 60 + Double(index) * 100))
            }
        }
    }
}
