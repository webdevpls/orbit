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
    private var monitor: InputMonitor?
    private var hotkey: Hotkey?
    private var cancellables: Set<AnyCancellable> = []
    private var previewWindows: [NSWindow] = []

    init() {
        ring = RingController(store: store)
        let previewing = CommandLine.arguments.contains { $0.hasPrefix("--preview") }
        // Previews stay still for screenshots, so they skip the mouse tap.
        let monitor = previewing ? nil : InputMonitor(store: store, ring: ring)
        self.monitor = monitor
        hotkey = Hotkey { monitor?.toggleFromHotkey() }
        store.$hotkey
            .sink { [weak self] choice in self?.hotkey?.set(choice) }
            .store(in: &cancellables)

        // Debug: `Orbit --preview-ring` opens the ring at the screen center on launch.
        if CommandLine.arguments.contains("--preview-ring") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [ring] in
                let frame = NSScreen.screens.first?.frame ?? .zero
                let x = CommandLine.arguments.contains("--preview-panel") ? frame.width * 0.36 : frame.midX
                ring.show(at: CGPoint(x: x, y: frame.midY), mode: .sticky)
                ring.select(2)
            }
        }
        // Debug: `Orbit --preview-panel` shows the menu bar panel in a window.
        if CommandLine.arguments.contains("--preview-panel") {
            DispatchQueue.main.async { [self] in
                let controller = NSHostingController(rootView:
                    PanelView()
                        .environmentObject(store)
                        .environmentObject(ring)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .glassCard(cornerRadius: 22)
                        .padding(30))
                controller.sizingOptions = [.preferredContentSize]
                let window = NSWindow(contentViewController: controller)
                window.styleMask = [.borderless]
                window.isOpaque = false
                window.backgroundColor = .clear
                window.level = .floating
                if let frame = NSScreen.screens.first?.frame {
                    window.setFrameOrigin(NSPoint(x: frame.width * 0.62 - window.frame.width / 2,
                                                  y: frame.midY - window.frame.height / 2))
                }
                window.orderFrontRegardless()
                previewWindows.append(window)
            }
        }
        // Debug: `Orbit --preview-backdrop` puts a colorful wallpaper behind the previews (for screenshots).
        if CommandLine.arguments.contains("--preview-backdrop"), let screen = NSScreen.screens.first {
            let window = NSWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.contentView = NSHostingView(rootView: PreviewBackdrop())
            window.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
            window.orderFrontRegardless()
            previewWindows.append(window)
        }
    }
}

/// Wallpaper-like gradient used only behind debug previews.
private struct PreviewBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.rgb(0x1B1446), Theme.rgb(0x0E2A47), Theme.rgb(0x2A0F3A)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Theme.violet).frame(width: 700).offset(x: -420, y: -260).blur(radius: 160)
            Circle().fill(Theme.teal).frame(width: 560).offset(x: 460, y: 220).blur(radius: 150)
            Circle().fill(Theme.pink).frame(width: 520).offset(x: 120, y: -330).blur(radius: 150)
            Circle().fill(Theme.orange).frame(width: 380).offset(x: -260, y: 360).blur(radius: 140).opacity(0.7)
        }
        .ignoresSafeArea()
    }
}
