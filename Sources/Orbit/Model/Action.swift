import AppKit

/// Built-in macOS actions that don't map to a single app or file.
enum SystemAction: String, Codable, CaseIterable, Identifiable {
    case screenshot, missionControl, apps, lockScreen, sleepDisplay, emoji, desktop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .screenshot: return "Screenshot"
        case .missionControl: return "Mission Control"
        case .apps: return "All Apps"
        case .lockScreen: return "Lock Screen"
        case .sleepDisplay: return "Sleep Display"
        case .emoji: return "Emoji & Symbols"
        case .desktop: return "Desktop Folder"
        }
    }

    var symbol: String {
        switch self {
        case .screenshot: return "camera.viewfinder"
        case .missionControl: return "rectangle.3.group"
        case .apps: return "square.grid.3x3.fill"
        case .lockScreen: return "lock.fill"
        case .sleepDisplay: return "moon.fill"
        case .emoji: return "face.smiling"
        case .desktop: return "menubar.dock.rectangle"
        }
    }
}

/// What a slot in the ring does when chosen.
enum Action: Codable, Hashable {
    case app(path: String)
    case website(url: String, name: String)
    case file(path: String)
    case shortcut(name: String)
    case system(SystemAction)

    var title: String {
        switch self {
        case .app(let path):
            return FileManager.default.displayName(atPath: path).replacingOccurrences(of: ".app", with: "")
        case .website(let url, let name):
            return name.isEmpty ? (URL(string: url)?.host ?? url).replacingOccurrences(of: "www.", with: "") : name
        case .file(let path):
            return FileManager.default.displayName(atPath: path)
        case .shortcut(let name):
            return name
        case .system(let action):
            return L(action.title)
        }
    }

    var kind: String {
        switch self {
        case .app: return "App"
        case .website: return "Website"
        case .file(let path):
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
            return isDir.boolValue ? "Folder" : "File"
        case .shortcut: return "Shortcut"
        case .system: return "System"
        }
    }

    /// Whether the target still exists (apps and files can be deleted after being added).
    var isAvailable: Bool {
        switch self {
        case .app(let path), .file(let path): return FileManager.default.fileExists(atPath: path)
        default: return true
        }
    }
}

/// One position in the ring.
struct Slot: Codable, Identifiable, Hashable {
    var id = UUID()
    var action: Action
}
