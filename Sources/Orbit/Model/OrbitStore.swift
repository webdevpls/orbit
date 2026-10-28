import AppKit
import Combine
import ServiceManagement

/// Mouse button that opens the ring.
enum MouseTrigger: String, CaseIterable, Identifiable {
    case middle, back, forward, off

    var id: String { rawValue }

    /// CGEvent button number (0 = left, 1 = right, 2 = middle, 3/4 = side buttons).
    var buttonNumber: Int64? {
        switch self {
        case .middle: return 2
        case .back: return 3
        case .forward: return 4
        case .off: return nil
        }
    }

    var title: String {
        switch self {
        case .middle: return "Scroll Wheel Click"
        case .back: return "Back Button"
        case .forward: return "Forward Button"
        case .off: return "Off"
        }
    }
}

/// Keyboard shortcut that opens the ring at the pointer.
enum HotkeyChoice: String, CaseIterable, Identifiable {
    case off, optionSpace, controlOptionSpace, optionCommandO

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: return "Off"
        case .optionSpace: return "⌥ Space"
        case .controlOptionSpace: return "⌃⌥ Space"
        case .optionCommandO: return "⌥⌘ O"
        }
    }
}

enum RingSize: String, CaseIterable, Identifiable {
    case small, medium, large

    var id: String { rawValue }
    var scale: CGFloat { self == .small ? 0.86 : self == .large ? 1.16 : 1 }
    var title: String { self == .small ? "Small" : self == .large ? "Large" : "Medium" }
}

@MainActor
final class OrbitStore: ObservableObject {
    static let maxSlots = 8

    @Published var slots: [Slot] { didSet { saveSlots() } }
    @Published var trigger: MouseTrigger { didSet { defaults.set(trigger.rawValue, forKey: "trigger") } }
    @Published var hotkey: HotkeyChoice { didSet { defaults.set(hotkey.rawValue, forKey: "hotkey") } }
    @Published var ringSize: RingSize { didSet { defaults.set(ringSize.rawValue, forKey: "ringSize") } }
    /// A quick click leaves the ring open so the user can click an item, instead of closing on release.
    @Published var clickToKeepOpen: Bool { didSet { defaults.set(clickToKeepOpen, forKey: "clickToKeepOpen") } }
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled {
        didSet { updateLoginItem() }
    }
    @Published private(set) var accessibilityTrusted = AXIsProcessTrusted()

    private let defaults = UserDefaults.standard
    private var permissionTimer: Timer?

    init() {
        if let data = defaults.data(forKey: "slots"), let saved = try? JSONDecoder().decode([Slot].self, from: data) {
            slots = saved
        } else {
            slots = Self.defaultSlots()
        }
        trigger = MouseTrigger(rawValue: defaults.string(forKey: "trigger") ?? "") ?? .middle
        hotkey = HotkeyChoice(rawValue: defaults.string(forKey: "hotkey") ?? "") ?? .optionSpace
        ringSize = RingSize(rawValue: defaults.string(forKey: "ringSize") ?? "") ?? .medium
        clickToKeepOpen = defaults.object(forKey: "clickToKeepOpen") as? Bool ?? true
        watchPermission()
    }

    // MARK: Slots

    var canAdd: Bool { slots.count < Self.maxSlots }

    func add(_ action: Action) {
        guard canAdd else { return }
        slots.append(Slot(action: action))
    }

    func replace(_ id: Slot.ID, with action: Action) {
        guard let index = slots.firstIndex(where: { $0.id == id }) else { return }
        slots[index].action = action
    }

    func remove(_ id: Slot.ID) {
        slots.removeAll { $0.id == id }
    }

    /// Moves a slot one step around the ring (positive = clockwise), wrapping at the ends.
    func move(_ id: Slot.ID, by step: Int) {
        guard let index = slots.firstIndex(where: { $0.id == id }), slots.count > 1 else { return }
        let target = (index + step + slots.count) % slots.count
        slots.swapAt(index, target)
    }

    func resetSlots() {
        slots = Self.defaultSlots()
    }

    private func saveSlots() {
        if let data = try? JSONEncoder().encode(slots) { defaults.set(data, forKey: "slots") }
    }

    private static func defaultSlots() -> [Slot] {
        let apps = [
            "/System/Library/CoreServices/Finder.app",
            "/Applications/Safari.app",
            "/System/Applications/Mail.app",
            "/System/Applications/Music.app",
            "/System/Applications/Notes.app",
            "/System/Applications/Calendar.app",
            "/System/Applications/System Settings.app",
        ]
        var slots = apps.filter(FileManager.default.fileExists(atPath:)).map { Slot(action: .app(path: $0)) }
        slots.insert(Slot(action: .system(.screenshot)), at: min(4, slots.count))
        return Array(slots.prefix(maxSlots))
    }

    // MARK: Permission

    /// Asks macOS to show the Accessibility prompt (it only appears once per app identity).
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        accessibilityTrusted = AXIsProcessTrustedWithOptions(options)
        if !accessibilityTrusted { openAccessibilitySettings() }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func watchPermission() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let trusted = AXIsProcessTrusted()
                if trusted != self.accessibilityTrusted { self.accessibilityTrusted = trusted }
            }
        }
    }

    private func updateLoginItem() {
        do {
            if launchAtLogin { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Orbit: login item update failed: \(error)")
        }
    }
}
