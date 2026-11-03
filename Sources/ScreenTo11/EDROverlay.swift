import AppKit
import MetalKit
import QuartzCore

/// A window owned by this process, so macOS removes its effect if the app exits.
@MainActor
final class EDROverlay {
    enum Purpose { case headroomRequest, multiplier }

    private let window: NSWindow
    private let view: EDRColorView
    let screenID: CGDirectDisplayID
    let frame: NSRect

    init?(screen: NSScreen, screenID: CGDirectDisplayID, purpose: Purpose, value: Double) {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        self.screenID = screenID
        self.frame = screen.frame

        let rect: NSRect
        switch purpose {
        case .headroomRequest:
            rect = NSRect(x: screen.frame.maxX - 2, y: screen.frame.maxY - 2, width: 2, height: 2)
        case .multiplier:
            rect = screen.frame
        }

        window = NSWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        view = EDRColorView(frame: NSRect(origin: .zero, size: rect.size), device: device,
                            multiply: purpose == .multiplier, value: value)
        window.contentView = view
        window.level = purpose == .multiplier
            ? NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
            : .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        window.acceptsMouseMovedEvents = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        window.sharingType = .none
        window.orderFrontRegardless()
    }

    func setValue(_ value: Double) { view.value = value }
    func close() { window.close() }
}

/// A floating point Metal surface is necessary: ordinary NSColor channels clip at SDR white.
private final class EDRColorView: MTKView, MTKViewDelegate {
    private let commandQueue: MTLCommandQueue?
    private let valueLock = NSLock()
    private var storedValue: Double

    var value: Double {
        get { valueLock.lock(); defer { valueLock.unlock() }; return storedValue }
        set { valueLock.lock(); storedValue = newValue; valueLock.unlock(); draw() }
    }

    init(frame: NSRect, device: MTLDevice, multiply: Bool, value: Double) {
        storedValue = value
        commandQueue = device.makeCommandQueue()
        super.init(frame: frame, device: device)
        colorPixelFormat = .rgba16Float
        colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        clearColor = MTLClearColor(red: value, green: value, blue: value, alpha: 1)
        preferredFramesPerSecond = multiply ? 30 : 2
        isPaused = false
        enableSetNeedsDisplay = false
        if let metalLayer = layer as? CAMetalLayer {
            metalLayer.wantsExtendedDynamicRangeContent = true
            metalLayer.isOpaque = false
            if multiply { metalLayer.compositingFilter = "multiply" }
        }
        delegate = self
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let commandQueue, let pass = currentRenderPassDescriptor,
              let drawable = currentDrawable,
              let buffer = commandQueue.makeCommandBuffer() else { return }
        let channel = value
        pass.colorAttachments[0].clearColor = MTLClearColor(
            red: channel, green: channel, blue: channel, alpha: 1)
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}
