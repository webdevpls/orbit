import AppKit
import Carbon.HIToolbox
import Combine

/// Watches the mouse through a CGEvent tap: opens the ring on the trigger button and swallows the
/// clicks, keys and scrolls that drive it so they never reach the app underneath.
/// Needs Accessibility permission (an active tap can modify or drop events).
@MainActor
final class InputMonitor {
    private let store: OrbitStore
    private let ring: RingController
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var cancellables: Set<AnyCancellable> = []

    private var heldButton: Int64?
    private var pressTime: Date = .distantPast
    /// Mouse-up events whose mouse-down we consumed, so the app underneath never sees half a click.
    private var swallowUp: Set<CGEventType> = []
    private var scrollAccumulator: Double = 0

    /// A press shorter than this, released without picking a slot, leaves the ring open.
    private let quickClickInterval: TimeInterval = 0.32

    init(store: OrbitStore, ring: RingController) {
        self.store = store
        self.ring = ring
        store.$accessibilityTrusted
            .removeDuplicates()
            .sink { [weak self] trusted in
                if trusted { self?.start() } else { self?.stop() }
            }
            .store(in: &cancellables)
    }

    var isRunning: Bool { tap != nil }

    func start() {
        guard tap == nil else { return }
        let types: [CGEventType] = [
            .otherMouseDown, .otherMouseUp, .otherMouseDragged, .mouseMoved,
            .leftMouseDown, .leftMouseUp, .leftMouseDragged, .rightMouseDown, .rightMouseUp,
            .keyDown, .scrollWheel,
        ]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << CGEventMask($1.rawValue)) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("Orbit: could not create the event tap (Accessibility permission missing?)")
            return
        }
        self.tap = tap
        source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        tap = nil
        source = nil
        ring.dismiss()
    }

    /// Opens the ring from the keyboard shortcut, in click-to-choose mode.
    func toggleFromHotkey() {
        if ring.isVisible {
            ring.dismiss()
        } else {
            ring.show(at: CGEvent(source: nil)?.location ?? .zero, mode: .sticky)
        }
    }

    // MARK: Event handling

    fileprivate func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)
        let location = event.location

        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return pass

        case .otherMouseDown:
            let button = event.getIntegerValueField(.mouseEventButtonNumber)
            if ring.isVisible {
                // Any extra button while open closes it; the trigger button in sticky mode toggles it off.
                ring.dismiss()
                swallowUp.insert(.otherMouseUp)
                return nil
            }
            guard button == store.trigger.buttonNumber else { return pass }
            heldButton = button
            pressTime = Date()
            ring.show(at: location, mode: .holding)
            return nil

        case .otherMouseUp:
            let button = event.getIntegerValueField(.mouseEventButtonNumber)
            if button == heldButton {
                heldButton = nil
                ring.endHold(quickClick: store.clickToKeepOpen && Date().timeIntervalSince(pressTime) < quickClickInterval)
                return nil
            }
            if swallowUp.remove(.otherMouseUp) != nil { return nil }
            return pass

        case .mouseMoved, .otherMouseDragged, .leftMouseDragged:
            if ring.isVisible { ring.track(location) }
            return pass

        case .leftMouseDown:
            guard ring.isVisible, heldButton == nil else { return pass }
            if ring.isOutside(location) {
                ring.dismiss()
            } else {
                ring.track(location)
                ring.commit()
            }
            swallowUp.insert(.leftMouseUp)
            return nil

        case .leftMouseUp:
            return swallowUp.remove(.leftMouseUp) != nil ? nil : pass

        case .rightMouseDown:
            guard ring.isVisible else { return pass }
            ring.dismiss()
            swallowUp.insert(.rightMouseUp)
            return nil

        case .rightMouseUp:
            return swallowUp.remove(.rightMouseUp) != nil ? nil : pass

        case .scrollWheel:
            guard ring.isVisible else { return pass }
            // Each notch (or a short trackpad swipe) moves one slot.
            let delta = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
            scrollAccumulator += delta
            if abs(scrollAccumulator) >= 12 {
                ring.step(scrollAccumulator > 0 ? -1 : 1)
                scrollAccumulator = 0
            }
            return nil

        case .keyDown:
            guard ring.isVisible else { return pass }
            // A modified key (such as the shortcut that opened the ring) just closes it.
            if !event.flags.intersection([.maskCommand, .maskControl, .maskAlternate]).isEmpty {
                ring.dismiss()
                return nil
            }
            return handleKey(Int(event.getIntegerValueField(.keyboardEventKeycode))) ? nil : pass

        default:
            return pass
        }
    }

    /// Keys while the ring is open: Esc closes, Return opens, arrows move, 1–8 open directly.
    private func handleKey(_ code: Int) -> Bool {
        let digits = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8]
        switch code {
        case kVK_Escape:
            ring.dismiss()
        case kVK_Return, kVK_ANSI_KeypadEnter, kVK_Space:
            ring.commit()
        case kVK_RightArrow, kVK_DownArrow, kVK_Tab:
            ring.step(1)
        case kVK_LeftArrow, kVK_UpArrow:
            ring.step(-1)
        default:
            if let index = digits.firstIndex(of: code) {
                ring.commit(index)
            } else {
                ring.dismiss()
                return false
            }
        }
        return true
    }
}

private func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                              refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let monitor = Unmanaged<InputMonitor>.fromOpaque(refcon).takeUnretainedValue()
    // The tap's run loop source is on the main run loop.
    return MainActor.assumeIsolated { monitor.handle(type, event) }
}
