import AppKit

/// Performs slot actions.
enum ActionRunner {
    static func run(_ action: Action) {
        let workspace = NSWorkspace.shared
        switch action {
        case .app(let path):
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            workspace.openApplication(at: URL(fileURLWithPath: path), configuration: config) { _, error in
                if let error { NSLog("Orbit: could not open \(path): \(error)") }
            }
        case .website(let string, _):
            if let url = URL(string: normalizedURL(string)) { workspace.open(url) }
        case .file(let path):
            workspace.open(URL(fileURLWithPath: path))
        case .shortcut(let name):
            launch("/usr/bin/shortcuts", ["run", name])
        case .system(let system):
            run(system)
        }
    }

    private static func run(_ action: SystemAction) {
        switch action {
        case .screenshot:
            openFirstApp(["/System/Applications/Utilities/Screenshot.app"])
        case .missionControl:
            openFirstApp(["/System/Applications/Mission Control.app"])
        case .apps:
            // macOS 26 replaced Launchpad with Apps.
            openFirstApp(["/System/Applications/Apps.app", "/System/Applications/Launchpad.app"])
        case .lockScreen:
            keystroke(12, flags: [.maskCommand, .maskControl]) // ⌃⌘Q
        case .sleepDisplay:
            launch("/usr/bin/pmset", ["displaysleepnow"])
        case .emoji:
            keystroke(49, flags: [.maskCommand, .maskControl]) // ⌃⌘Space
        case .desktop:
            NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop"))
        }
    }

    /// Adds https:// when the user typed a bare domain.
    static func normalizedURL(_ string: String) -> String {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("://") ? trimmed : "https://" + trimmed
    }

    private static func openFirstApp(_ paths: [String]) {
        guard let path = paths.first(where: FileManager.default.fileExists(atPath:)) else { return }
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: .init())
    }

    private static func launch(_ tool: String, _ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        try? process.run()
    }

    private static func keystroke(_ key: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        for down in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down)
            event?.flags = flags
            event?.post(tap: .cghidEventTap)
        }
    }
}
