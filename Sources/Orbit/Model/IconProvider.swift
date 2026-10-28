import AppKit
import SwiftUI

/// Resolves and caches the artwork shown for each action.
@MainActor
final class IconProvider: ObservableObject {
    static let shared = IconProvider()

    enum Icon {
        case image(NSImage)
        case symbol(String)
    }

    private var images: [String: NSImage] = [:]
    private var pendingFavicons: Set<String> = []
    private let cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Orbit/Favicons", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func icon(for action: Action) -> Icon {
        switch action {
        case .app(let path), .file(let path):
            return .image(fileIcon(path))
        case .shortcut:
            return .image(fileIcon("/System/Applications/Shortcuts.app"))
        case .system(let system):
            return .symbol(system.symbol)
        case .website(let url, _):
            guard let host = URL(string: ActionRunner.normalizedURL(url))?.host else { return .symbol("globe") }
            if let image = images["web:" + host] { return .image(image) }
            loadFavicon(host)
            return .symbol("globe")
        }
    }

    func fileIcon(_ path: String) -> NSImage {
        if let image = images[path] { return image }
        let image = NSWorkspace.shared.icon(forFile: path)
        image.size = NSSize(width: 128, height: 128)
        images[path] = image
        return image
    }

    /// Fetches the site's touch icon (or favicon) straight from the site itself, once, and keeps it on disk.
    private func loadFavicon(_ host: String) {
        let key = "web:" + host
        let file = cacheDir.appendingPathComponent(host + ".png")
        if let image = NSImage(contentsOf: file) {
            images[key] = image
            return
        }
        guard !pendingFavicons.contains(host) else { return }
        pendingFavicons.insert(host)

        Task {
            let candidates = ["apple-touch-icon.png", "apple-touch-icon-precomposed.png", "favicon.ico"]
            for name in candidates {
                guard let url = URL(string: "https://\(host)/\(name)"),
                      let (data, response) = try? await URLSession.shared.data(from: url),
                      (response as? HTTPURLResponse)?.statusCode == 200,
                      let image = NSImage(data: data), image.size.width >= 16
                else { continue }
                if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
                   let png = rep.representation(using: .png, properties: [:]) {
                    try? png.write(to: file)
                }
                images[key] = image
                objectWillChange.send()
                return
            }
        }
    }
}

/// Draws an action's icon: app/file artwork as-is, SF Symbols in a soft glass tile.
struct ActionIcon: View {
    let action: Action
    var size: CGFloat = 40
    @ObservedObject private var provider = IconProvider.shared

    var body: some View {
        switch provider.icon(for: action) {
        case .image(let image):
            if case .website = action {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.78, height: size * 0.78)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
                    .frame(width: size, height: size)
            } else {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            }
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                .frame(width: size * 0.82, height: size * 0.82)
                .background(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .fill(LinearGradient(colors: Theme.symbolColors(for: action), startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .frame(width: size, height: size)
        }
    }
}
