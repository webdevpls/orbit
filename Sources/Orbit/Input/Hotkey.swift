import Carbon.HIToolbox

/// A system-wide keyboard shortcut through Carbon's hot key API (works without extra permissions).
@MainActor
final class Hotkey {
    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let onPress: () -> Void

    init(onPress: @escaping () -> Void) {
        self.onPress = onPress
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let hotkey = Unmanaged<Hotkey>.fromOpaque(userData).takeUnretainedValue()
            MainActor.assumeIsolated { hotkey.onPress() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    func set(_ choice: HotkeyChoice) {
        if let ref { UnregisterEventHotKey(ref) }
        ref = nil
        let combo: (key: Int, modifiers: Int)
        switch choice {
        case .off: return
        case .optionSpace: combo = (kVK_Space, optionKey)
        case .controlOptionSpace: combo = (kVK_Space, controlKey | optionKey)
        case .optionCommandO: combo = (kVK_ANSI_O, optionKey | cmdKey)
        }
        let id = EventHotKeyID(signature: OSType(0x4F52_4254), id: 1) // "ORBT"
        RegisterEventHotKey(UInt32(combo.key), UInt32(combo.modifiers), id, GetApplicationEventTarget(), 0, &ref)
    }
}
