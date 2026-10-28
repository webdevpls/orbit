import AppKit

struct InstalledApp: Identifiable, Hashable {
    let name: String
    let path: String
    var id: String { path }
}

/// Lists what the user can put in the ring: installed apps and Shortcuts.
enum Catalog {
    static func installedApps() -> [InstalledApp] {
        let fm = FileManager.default
        let roots = [
            "/Applications", "/Applications/Utilities", "/System/Applications", "/System/Applications/Utilities",
            fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path,
        ]
        var seen = Set<String>()
        var apps: [InstalledApp] = []

        func scan(_ dir: String, depth: Int) {
            guard let items = try? fm.contentsOfDirectory(atPath: dir) else { return }
            for item in items where !item.hasPrefix(".") {
                let path = (dir as NSString).appendingPathComponent(item)
                if item.hasSuffix(".app") {
                    let name = fm.displayName(atPath: path).replacingOccurrences(of: ".app", with: "")
                    if seen.insert(name.lowercased()).inserted { apps.append(InstalledApp(name: name, path: path)) }
                } else if depth > 0 {
                    var isDir: ObjCBool = false
                    if fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue { scan(path, depth: depth - 1) }
                }
            }
        }

        // Finder lives outside the usual app folders.
        apps.append(InstalledApp(name: "Finder", path: "/System/Library/CoreServices/Finder.app"))
        seen.insert("finder")
        for root in roots { scan(root, depth: 1) }
        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func shortcuts() async -> [String] {
        await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            process.arguments = ["list"]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            guard (try? process.run()) != nil else { return [] }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(decoding: data, as: UTF8.self)
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        }.value
    }
}
