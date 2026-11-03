import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DisplayController.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        DisplayController.shared.stop()
    }
}

@main
struct ScreenTo11App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var display = DisplayController.shared

    var body: some Scene {
        MenuBarExtra("Screen to 11", systemImage: "sun.max.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Screen to 11").font(.headline)

                Toggle("Enable boost", isOn: Binding(
                    get: { display.isEnabled },
                    set: { display.setEnabled($0) }
                ))
                .disabled(!display.canBoost)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Boost")
                        Spacer()
                        Text("\(Int((display.level * 100).rounded()))%")
                            .monospacedDigit()
                    }
                    Slider(value: Binding(
                        get: { display.level },
                        set: { display.setLevel($0) }
                    ), in: 0...1)
                    .disabled(!display.canBoost || !display.isEnabled || display.current <= 1.001)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(display.status).foregroundStyle(.secondary)
                    Text(display.screenName).foregroundStyle(.secondary)
                    Text(String(format: "EDR headroom: current %.2f× · potential %.2f×",
                                display.current, display.potential))
                        .foregroundStyle(.secondary)
                    if display.isEnabled {
                        Text(String(format: "Effective gain: %.2f×", display.effective))
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)

                Divider()
                Toggle("Launch at Login", isOn: Binding(
                    get: { display.launchAtLogin },
                    set: { display.setLaunchAtLogin($0) }
                ))
                if let message = display.loginMessage {
                    Text(message).font(.caption).foregroundStyle(.orange)
                }
                Divider()
                Button("Quit Screen to 11") {
                    display.stop()
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(14)
            .frame(width: 285)
        }
        .menuBarExtraStyle(.window)
    }
}
