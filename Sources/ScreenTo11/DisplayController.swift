import AppKit
import Combine
import CoreGraphics
import ServiceManagement

@MainActor
final class DisplayController: ObservableObject {
    static let shared = DisplayController()

    @Published private(set) var isEnabled = false
    @Published private(set) var level: Double
    @Published private(set) var potential: Double = 1
    @Published private(set) var current: Double = 1
    @Published private(set) var effective: Double = 1
    @Published private(set) var screenName = "Built-in display unavailable"
    @Published private(set) var renderingAvailable = true
    @Published private(set) var launchAtLogin = false
    @Published private(set) var loginMessage: String?

    private var headroomWindow: EDROverlay?
    private var boostWindow: EDROverlay?
    private var activeID: CGDirectDisplayID?
    private var activeFrame: NSRect?
    private var timer: Timer?
    private var screenObserver: NSObjectProtocol?
    private var spaceObserver: NSObjectProtocol?

    private init() {
        level = UserDefaults.standard.object(forKey: "boostLevel") as? Double ?? 0.5
        level = min(max(level, 0), 1)
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func start() {
        guard timer == nil else { return }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.refresh() } }
        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.refresh() } }
        timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        refresh()
    }

    var canBoost: Bool { renderingAvailable && potential > 1.001 }

    var status: String {
        if screenName == "Built-in display unavailable" { return "No built-in display in this session." }
        if !renderingAvailable { return "Metal EDR rendering is unavailable." }
        if potential <= 1.001 { return "This display reports no EDR headroom." }
        if isEnabled && current <= 1.001 { return "Waiting for usable EDR headroom." }
        if isEnabled && current < potential - 0.01 {
            return "Boost active within the current EDR limit."
        }
        return isEnabled ? "Boost active" : "Boost off"
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled && canBoost else {
            isEnabled = false
            removeWindows()
            effective = 1
            return
        }
        isEnabled = true
        refresh()
    }

    func setLevel(_ newValue: Double) {
        level = min(max(newValue, 0), 1)
        UserDefaults.standard.set(level, forKey: "boostLevel")
        refresh()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        loginMessage = nil
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            loginMessage = error.localizedDescription
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
        if SMAppService.mainApp.status == .requiresApproval {
            loginMessage = "Approve Screen to 11 in System Settings → Login Items."
        }
    }

    func refresh() {
        guard let (screen, id) = builtInScreen() else {
            screenName = "Built-in display unavailable"
            potential = 1; current = 1; effective = 1
            removeWindows()
            return
        }
        screenName = screen.localizedName
        potential = max(1, screen.maximumPotentialExtendedDynamicRangeColorComponentValue)
        current = max(1, screen.maximumExtendedDynamicRangeColorComponentValue)
        if !isEnabled || potential <= 1.001 {
            if potential <= 1.001 { isEnabled = false }
            effective = 1
            removeWindows()
            return
        }

        if activeID != id || activeFrame != screen.frame {
            removeWindows()
        }
        activeID = id
        activeFrame = screen.frame

        if headroomWindow == nil {
            headroomWindow = EDROverlay(screen: screen, screenID: id,
                                        purpose: .headroomRequest,
                                        value: min(2, potential))
            if headroomWindow == nil {
                renderingAvailable = false
                isEnabled = false
                effective = 1
                return
            }
        }

        // NSScreen's current limit can rise only after EDR drawing starts.
        current = max(1, screen.maximumExtendedDynamicRangeColorComponentValue)
        effective = GainPolicy.effectiveGain(level: level, potential: potential, current: current)
        if let boostWindow {
            boostWindow.setValue(effective)
        } else {
            boostWindow = EDROverlay(screen: screen, screenID: id,
                                     purpose: .multiplier, value: effective)
            if boostWindow == nil { renderingAvailable = false; setEnabled(false) }
        }
    }

    func stop() {
        isEnabled = false
        removeWindows()
        effective = 1
        timer?.invalidate()
        timer = nil
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        if let spaceObserver { NSWorkspace.shared.notificationCenter.removeObserver(spaceObserver) }
        screenObserver = nil
        spaceObserver = nil
    }

    private func removeWindows() {
        boostWindow?.close(); boostWindow = nil
        headroomWindow?.close(); headroomWindow = nil
        activeID = nil; activeFrame = nil
    }

    private func builtInScreen() -> (NSScreen, CGDirectDisplayID)? {
        for screen in NSScreen.screens {
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { continue }
            let id = CGDirectDisplayID(number.uint32Value)
            if CGDisplayIsBuiltin(id) != 0 { return (screen, id) }
        }
        return nil
    }
}
