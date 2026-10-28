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
            if let path = matchingApp(for: action) { return .image(fileIcon(path)) }
            guard let host = URL(string: ActionRunner.normalizedURL(url))?.host else { return .symbol("globe") }
            if let image = images["web:" + host] { return .image(image) }
            loadFavicon(host)
            return .symbol("globe")
        }
    }

    /// Installed apps by normalized name ("chatgpt", "whatsapp", "googledrive"…).
    private lazy var appsByName: [String: String] = {
        Dictionary(Catalog.installedApps().map { (Self.normalize($0.name), $0.path) }, uniquingKeysWith: { first, _ in first })
    }()

    /// An installed app for a website, when its name or domain matches (chatgpt.com → ChatGPT.app).
    /// Its icon looks better than a favicon, and some sites block favicon downloads.
    func matchingApp(for action: Action) -> String? {
        guard case .website(let url, let name) = action else { return nil }
        var keys = [Self.normalize(name)]
        if let labels = URL(string: ActionRunner.normalizedURL(url))?.host?.split(separator: "."), labels.count >= 2 {
            keys.append(Self.normalize(String(labels[labels.count - 2]))) // domain without TLD or subdomain
        }
        return keys.lazy.filter { !$0.isEmpty }.compactMap { self.appsByName[$0] }.first
    }

    private static func normalize(_ string: String) -> String {
        string.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private var tints: [String: Color] = [:]

    /// The icon's most vivid color, for the glow behind the selected item.
    func tint(for action: Action) -> Color {
        switch icon(for: action) {
        case .symbol:
            return Theme.symbolColors(for: action)[0]
        case .image(let image):
            let key = "\(action)"
            if let tint = tints[key] { return tint }
            let tint = Self.vividColor(of: image) ?? Theme.violet
            tints[key] = tint
            return tint
        }
    }

    /// Averages a 12×12 thumbnail, weighting saturated, opaque pixels, then brightens the result.
    private static func vividColor(of image: NSImage) -> Color? {
        let side = 12
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8,
                                         samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0)
        else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
        NSGraphicsContext.restoreGraphicsState()

        var r = 0.0, g = 0.0, b = 0.0, total = 0.0
        for x in 0..<side {
            for y in 0..<side {
                guard let c = rep.colorAt(x: x, y: y), c.alphaComponent > 0.5 else { continue }
                let weight = 0.05 + c.saturationComponent * c.saturationComponent * c.brightnessComponent
                r += c.redComponent * weight
                g += c.greenComponent * weight
                b += c.blueComponent * weight
                total += weight
            }
        }
        guard total > 0 else { return nil }
        let average = NSColor(red: r / total, green: g / total, blue: b / total, alpha: 1)
        return Color(hue: average.hueComponent, saturation: min(average.saturationComponent * 1.3 + 0.15, 1),
                     brightness: max(average.brightnessComponent, 0.85))
    }

    func fileIcon(_ path: String) -> NSImage {
        if let image = images[path] { return image }
        let image = NSWorkspace.shared.icon(forFile: path)
        image.size = NSSize(width: 128, height: 128)
        images[path] = image
        return image
    }

    /// Fetches the site's touch icon (or favicon) once and keeps it on disk. Tries the site itself first; sites that
    /// block it (Cloudflare challenges, like chatgpt.com) fall back to DuckDuckGo's icon service.
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
                .map { "https://\(host)/\($0)" } + ["https://icons.duckduckgo.com/ip3/\(host).ico"]
            for candidate in candidates {
                guard let url = URL(string: candidate),
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
            if case .website = action, provider.matchingApp(for: action) == nil {
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
