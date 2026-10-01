import LiquidGlassEffects
import SwiftUI

/// `GLASSLAB_AUTOPILOT=1 swift run` plays a looping tour with no controls. It is what the README
/// animation was recorded from. Add `GLASSLAB_STOP=3` to stay on one stop of the tour.
///
/// For a smooth recording, `GLASSLAB_FRAME_FILE=/tmp/frame` makes the tour draw exactly the frame
/// number written in that file (at ``framesPerSecond``), so a script can step through it and
/// screenshot each frame, whatever the screenshots cost.
enum Autopilot {
    static let isEnabled = ProcessInfo.processInfo.environment["GLASSLAB_AUTOPILOT"] != nil
    static let size = CGSize(width: 760, height: 460)

    struct Stop {
        var variant: GlassVariant
        var subvariant: GlassSubvariant?
        var shape: ShapeChoice
    }

    /// Variants that look clearly different over the scene backdrop.
    static let tour: [Stop] = [
        Stop(variant: .bubbles, subvariant: nil, shape: .roundedRectangle),
        Stop(variant: .loupe, subvariant: nil, shape: .circle),
        Stop(variant: .dock, subvariant: nil, shape: .capsule),
        Stop(variant: .avplayer, subvariant: nil, shape: .roundedRectangle),
        Stop(variant: .bubbles, subvariant: nil, shape: .star),
        Stop(variant: .regular, subvariant: nil, shape: .roundedRectangle),
    ]

    static let frozenStop = ProcessInfo.processInfo.environment["GLASSLAB_STOP"].flatMap(Int.init).map { min(max($0, 0), tour.count - 1) }

    static let frameFile = ProcessInfo.processInfo.environment["GLASSLAB_FRAME_FILE"]
    static let framesPerSecond = 12.0

    static let secondsPerStop = 1.3
    static var loop: Double { Double(tour.count) * secondsPerStop }

    /// Seconds into the tour: the wall clock, or the frame named in ``frameFile`` when recording.
    static func phase(at date: Date) -> Double {
        if let frameFile {
            let text = (try? String(contentsOfFile: frameFile, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (Double(text.flatMap(Int.init) ?? 0) / framesPerSecond).truncatingRemainder(dividingBy: loop)
        }
        return date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: loop)
    }
}

struct AutopilotView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = Autopilot.phase(at: timeline.date)
            let stop = Autopilot.tour[Autopilot.frozenStop ?? min(Int(phase / Autopilot.secondsPerStop), Autopilot.tour.count - 1)]
            let turn = phase / Autopilot.loop * 2 * .pi
            let offset = CGSize(width: sin(turn) * 150, height: sin(turn * 2) * 55)

            ZStack(alignment: .bottomLeading) {
                SceneBackdrop()
                glass(for: stop)
                    .offset(offset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(".\(stop.variant)" + (stop.shape == .roundedRectangle ? "" : ", in: \(stop.shape.rawValue)()"))
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.55), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(28)
            }
            .clipped()
        }
    }

    @ViewBuilder
    private func glass(for stop: Autopilot.Stop) -> some View {
        let size = stop.shape == .circle || stop.shape == .star ? CGSize(width: 170, height: 170) : CGSize(width: 260, height: 130)
        let panel = Color.clear.frame(width: size.width, height: size.height)
        switch stop.shape {
        case .roundedRectangle: panel.privateGlassBackground(stop.variant, subvariant: stop.subvariant, cornerRadius: 30)
        case .capsule: panel.privateGlassBackground(stop.variant, subvariant: stop.subvariant, in: Capsule())
        case .circle: panel.privateGlassBackground(stop.variant, subvariant: stop.subvariant, in: Circle())
        case .star: panel.privateGlassBackground(stop.variant, subvariant: stop.subvariant, in: Star())
        case .hexagon: panel.privateGlassBackground(stop.variant, subvariant: stop.subvariant, in: Hexagon())
        }
    }
}
