import SwiftUI

@main
struct GlassLabApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        WindowGroup("GlassLab") {
            if Autopilot.isEnabled {
                AutopilotView()
                    .frame(width: Autopilot.size.width, height: Autopilot.size.height)
            } else {
                ContentView()
            }
        }
        .windowResizability(Autopilot.isEnabled ? .contentSize : .automatic)
        .defaultSize(width: 1180, height: 760)
    }
}

/// A command-line executable starts without a Dock icon or focus; this gives it both.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
