import AppKit
import SwiftUI

/// Sizes of the ring, scaled by the user's ring size setting.
struct RingGeometry {
    var scale: CGFloat = 1
    var radius: CGFloat { 100 * scale }
    var bubble: CGFloat { 60 * scale }
    var hub: CGFloat { 84 * scale }
    /// Pointer distance from the center below which nothing is selected.
    var deadZone: CGFloat { hub * 0.42 }
    var outerRadius: CGFloat { radius + bubble / 2 + 14 }
    var canvas: CGFloat { (radius + bubble) * 2 + 40 }

    /// Offset of slot `index` from the center; slot 0 is at the top, then clockwise.
    func offset(_ index: Int, of count: Int) -> CGSize {
        let angle = angle(index, of: count)
        return CGSize(width: radius * cos(angle), height: radius * sin(angle))
    }

    func angle(_ index: Int, of count: Int) -> CGFloat {
        -.pi / 2 + CGFloat(index) / CGFloat(max(count, 1)) * 2 * .pi
    }
}

/// Shows the ring in a floating, click-through panel and tracks which slot the pointer points at.
@MainActor
final class RingController: ObservableObject {
    enum Mode { case holding, sticky }

    @Published private(set) var slots: [Slot] = []
    @Published private(set) var selected: Int?
    @Published private(set) var presented = false
    @Published private(set) var firing: Int?
    @Published private(set) var geometry = RingGeometry()

    private(set) var isVisible = false
    private(set) var mode: Mode = .holding
    /// Ring center in Quartz coordinates (top-left origin), the same space CGEvent locations use.
    private var center: CGPoint = .zero
    private var generation = 0
    private let store: OrbitStore
    private lazy var panel = makePanel()

    init(store: OrbitStore) {
        self.store = store
    }

    // MARK: Showing

    func show(at point: CGPoint, mode: Mode) {
        slots = store.slots
        geometry = RingGeometry(scale: store.ringSize.scale)
        self.mode = mode
        selected = nil
        firing = nil
        generation += 1

        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let cocoa = CGPoint(x: point.x, y: primaryHeight - point.y)
        let screen = NSScreen.screens.first { NSMouseInRect(cocoa, $0.frame, false) } ?? NSScreen.main
        var centerCocoa = cocoa
        if let frame = screen?.visibleFrame {
            // Keep every bubble on screen when opened near an edge.
            let inset = geometry.outerRadius
            centerCocoa.x = min(max(cocoa.x, frame.minX + inset), frame.maxX - inset)
            centerCocoa.y = min(max(cocoa.y, frame.minY + inset), frame.maxY - inset)
        }
        center = CGPoint(x: centerCocoa.x, y: primaryHeight - centerCocoa.y)

        let size = geometry.canvas
        panel.setFrame(NSRect(x: centerCocoa.x - size / 2, y: centerCocoa.y - size / 2, width: size, height: size),
                       display: false)
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        isVisible = true

        presented = false
        DispatchQueue.main.async { [self] in
            withAnimation(.spring(response: 0.38, dampingFraction: 0.74)) { presented = true }
        }
        track(point)
    }

    func dismiss() {
        guard isVisible else { return }
        isVisible = false
        let current = generation
        withAnimation(.easeIn(duration: 0.14)) { presented = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [self] in
            if generation == current { panel.orderOut(nil) }
        }
    }

    // MARK: Interaction

    /// Updates the selection from the pointer's angle around the center.
    func track(_ point: CGPoint) {
        guard isVisible, !slots.isEmpty, firing == nil else { return }
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = hypot(dx, dy)
        var index: Int?
        if distance >= geometry.deadZone {
            let step = 2 * CGFloat.pi / CGFloat(slots.count)
            var angle = atan2(dy, dx) + .pi / 2 // 0 at the top, clockwise (Quartz y grows downward)
            if angle < 0 { angle += 2 * .pi }
            index = Int((angle / step).rounded()) % slots.count
        }
        select(index)
    }

    /// Moves the selection by whole slots (scroll wheel and arrow keys).
    func step(_ delta: Int) {
        guard isVisible, !slots.isEmpty else { return }
        let start = selected ?? (delta > 0 ? -1 : 0)
        select((start + delta + slots.count) % slots.count)
    }

    func select(_ index: Int?) {
        guard index != selected else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { selected = index }
        if index != nil { NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now) }
    }

    /// Whether a point is far enough outside the ring to count as "clicked away".
    func isOutside(_ point: CGPoint) -> Bool {
        hypot(point.x - center.x, point.y - center.y) > geometry.outerRadius
    }

    /// Runs the selected slot (or the given one) and closes the ring.
    func commit(_ index: Int? = nil) {
        guard isVisible else { return }
        guard let index = index ?? selected, slots.indices.contains(index) else {
            dismiss()
            return
        }
        let action = slots[index].action
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            selected = index
            firing = index
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) { [self] in
            dismiss()
            ActionRunner.run(action)
        }
    }

    /// Mouse button released: launch what's under the pointer, or stay open after a quick click.
    func endHold(quickClick: Bool) {
        guard isVisible, mode == .holding else { return }
        if selected != nil {
            commit()
        } else if quickClick {
            mode = .sticky
        } else {
            dismiss()
        }
    }

    // MARK: Panel

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.ignoresMouseEvents = true // All input arrives through the event tap.
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let host = NSHostingView(rootView: RingView().environmentObject(self))
        host.sizingOptions = []
        panel.contentView = host
        return panel
    }
}
