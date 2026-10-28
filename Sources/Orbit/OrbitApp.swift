import Combine
import SwiftUI

@main
struct OrbitApp: App {
    @StateObject private var services = Services()

    var body: some Scene {
        MenuBarExtra {
            PanelView()
                .environmentObject(services.store)
                .environmentObject(services.ring)
        } label: {
            Image(nsImage: Self.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }

    /// The Orbit mark as an 18 pt template image.
    private static let menuBarIcon: NSImage = {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let c = CGPoint(x: rect.midX, y: rect.midY)
            let r = size * 0.36
            let dot = size * 0.17
            NSColor.black.setFill()
            for i in 0..<8 {
                let a = Double(i) / 8 * 2 * .pi
                NSBezierPath(ovalIn: NSRect(x: c.x + r * cos(a) - dot / 2, y: c.y + r * sin(a) - dot / 2,
                                            width: dot, height: dot)).fill()
            }
            let hub = size * 0.32
            let ring = NSBezierPath(ovalIn: NSRect(x: c.x - hub / 2, y: c.y - hub / 2, width: hub, height: hub))
            ring.lineWidth = 1.6
            NSColor.black.setStroke()
            ring.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }()
}

/// Owns the long-lived pieces: settings, the ring window, the mouse tap and the shortcut.
@MainActor
final class Services: ObservableObject {
    let store = OrbitStore()
    let ring: RingController
    private let monitor: InputMonitor
    private var hotkey: Hotkey?
    private var cancellables: Set<AnyCancellable> = []
    private var previewWindow: NSWindow?

    init() {
        ring = RingController(store: store)
        monitor = InputMonitor(store: store, ring: ring)
        let monitor = monitor
        hotkey = Hotkey { monitor.toggleFromHotkey() }
        store.$hotkey
            .sink { [weak self] choice in self?.hotkey?.set(choice) }
            .store(in: &cancellables)

        // Debug: `Orbit --preview-ring` opens the ring at the screen center on launch.
        if CommandLine.arguments.contains("--preview-ring") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [ring] in
                let frame = NSScreen.screens.first?.frame ?? .zero
                ring.show(at: CGPoint(x: frame.midX, y: frame.midY), mode: .sticky)
                ring.select(2)
            }
        }
        // Debug: `Orbit --preview-panel` shows the menu bar panel in a window.
        if CommandLine.arguments.contains("--preview-panel") {
            DispatchQueue.main.async { [self] in
                let host = NSHostingView(rootView: PanelView().environmentObject(store).environmentObject(ring))
                let window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 320, height: 560),
                                      styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
                window.titlebarAppearsTransparent = true
                window.isOpaque = false
                window.backgroundColor = .clear
                window.contentView = host
                window.setContentSize(host.fittingSize)
                window.level = .floating
                window.center()
                window.orderFrontRegardless()
                previewWindow = window
            }
        }
    }
}
