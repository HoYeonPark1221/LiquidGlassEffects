import LiquidGlassEffects
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var model = LabModel()

    var body: some View {
        NavigationSplitView {
            VariantList(model: model)
                .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
        } detail: {
            if model.showsGallery {
                GlassVariantGalleryView()
            } else {
                HStack(spacing: 0) {
                    Playground(model: model)
                    Divider()
                    Inspector(model: model)
                        .frame(width: 310)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Picker("View", selection: $model.showsGallery) {
                    Text("Playground").tag(false)
                    Text("All 24").tag(true)
                }
                .pickerStyle(.segmented)
            }
        }
        .frame(minWidth: 960, minHeight: 620)
    }
}

// MARK: - Sidebar

private struct VariantList: View {
    @Bindable var model: LabModel

    var body: some View {
        List(selection: Binding(get: { model.variant }, set: {
            guard let variant = $0 else { return }
            model.variant = variant
            model.showsGallery = false
        })) {
            Section("Variants") {
                ForEach(GlassVariant.allCases) { variant in
                    HStack {
                        Text(variant.label)
                        Spacer()
                        Text("#\(variant.rawValue)").foregroundStyle(.secondary).monospacedDigit()
                    }
                    .opacity(variant.drawsOnItsOwn ? 1 : 0.45)
                    .help(variant.drawsOnItsOwn ? "" : "Draws nothing when used as a plain background")
                    .tag(variant)
                }
            }
        }
    }
}

// MARK: - Playground

private struct Playground: View {
    @Bindable var model: LabModel
    @State private var offset = CGSize.zero
    @State private var dragStart = CGSize.zero

    var body: some View {
        ZStack {
            BackdropView(choice: model.backdrop, image: model.customImage)
            panel
                .overlay { dragHandle }
                .offset(offset)
        }
        .clipped()
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, let image = NSImage(contentsOf: url) else { return false }
            model.customImage = image
            model.backdrop = .image
            return true
        }
    }

    /// Sits above the glass so the drag never depends on how the AppKit view behind it handles events.
    private var dragHandle: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { offset = CGSize(width: dragStart.width + $0.translation.width, height: dragStart.height + $0.translation.height) }
                    .onEnded { _ in dragStart = offset }
            )
    }

    private var panel: some View {
        glass(
            VStack(spacing: 4) {
                Text("Liquid Glass").font(.title2.weight(.semibold))
                Text(caption).font(.callout).opacity(0.85)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 3)
            .frame(width: model.width, height: model.height)
        )
    }

    private var caption: String {
        model.variant.label + (model.subvariant.map { " · \($0.rawValue)" } ?? "")
    }

    @ViewBuilder
    private func glass(_ content: some View) -> some View {
        let tint: Color? = model.usesTint ? model.tint : nil
        switch model.shape {
        case .roundedRectangle:
            content.privateGlassBackground(model.variant, subvariant: model.subvariant, cornerRadius: model.cornerRadius, tint: tint, isInteractive: model.isInteractive)
        case .capsule:
            content.privateGlassBackground(model.variant, subvariant: model.subvariant, in: Capsule(), tint: tint, isInteractive: model.isInteractive)
        case .circle:
            content.privateGlassBackground(model.variant, subvariant: model.subvariant, in: Circle(), tint: tint, isInteractive: model.isInteractive)
        case .star:
            content.privateGlassBackground(model.variant, subvariant: model.subvariant, in: Star(), tint: tint, isInteractive: model.isInteractive)
        case .hexagon:
            content.privateGlassBackground(model.variant, subvariant: model.subvariant, in: Hexagon(), tint: tint, isInteractive: model.isInteractive)
        }
    }
}

// MARK: - Inspector

private struct Inspector: View {
    @Bindable var model: LabModel

    var body: some View {
        Form {
            Section("Material") {
                Picker("Variant", selection: $model.variant) {
                    ForEach(GlassVariant.allCases) { Text("\($0.label)  #\($0.rawValue)").tag($0) }
                }
                Picker("Subvariant", selection: $model.subvariant) {
                    Text("None").tag(GlassSubvariant?.none)
                    Divider()
                    ForEach(GlassSubvariant.allCases) { Text($0.rawValue).tag(Optional($0)) }
                }
                ColorToggle(isOn: $model.usesTint, color: $model.tint)
                Toggle("Interactive (macOS 27)", isOn: $model.isInteractive)
            }

            Section("Shape") {
                Picker("Outline", selection: $model.shape) {
                    ForEach(ShapeChoice.allCases) { Text($0.rawValue).tag($0) }
                }
                if model.shape == .roundedRectangle {
                    LabeledSlider("Corner radius", value: $model.cornerRadius, in: 0...75)
                }
                LabeledSlider("Width", value: $model.width, in: 90...600)
                LabeledSlider("Height", value: $model.height, in: 60...400)
            }

            Section("Backdrop") {
                Picker("Backdrop", selection: $model.backdrop) {
                    ForEach(BackdropChoice.allCases) { Text($0.rawValue).tag($0) }
                }
                Button("Choose image…") { chooseImage() }
            }

            Section("Code") {
                Text(model.code)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(model.code, forType: .string)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        guard panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) else { return }
        model.customImage = image
        model.backdrop = .image
    }
}

private struct ColorToggle: View {
    @Binding var isOn: Bool
    @Binding var color: Color

    var body: some View {
        HStack {
            Toggle("Tint", isOn: $isOn)
            Spacer()
            ColorPicker("Tint colour", selection: $color).labelsHidden().disabled(!isOn)
        }
    }
}

private struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    init(_ title: String, value: Binding<Double>, in range: ClosedRange<Double>) {
        self.title = title
        self._value = value
        self.range = range
    }

    var body: some View {
        LabeledContent(title) {
            HStack {
                Slider(value: $value, in: range)
                Text("\(Int(value))").monospacedDigit().foregroundStyle(.secondary).frame(width: 32, alignment: .trailing)
            }
        }
    }
}
