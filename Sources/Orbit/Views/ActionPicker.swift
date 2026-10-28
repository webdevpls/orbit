import SwiftUI

private enum Category: String, CaseIterable {
    case apps, websites, files, shortcuts, system

    var title: String {
        switch self {
        case .apps: return "Apps"
        case .websites: return "Sites"
        case .files: return "Files"
        case .shortcuts: return "Shortcuts"
        case .system: return "System"
        }
    }

    var symbol: String {
        switch self {
        case .apps: return "square.grid.2x2.fill"
        case .websites: return "globe"
        case .files: return "folder.fill"
        case .shortcuts: return "square.stack.3d.up.fill"
        case .system: return "gearshape.2.fill"
        }
    }
}

/// Chooses what goes in a slot: an app, a site, a file or folder, a Shortcut or a system action.
struct ActionPicker: View {
    let replacing: Slot.ID?
    let onPick: (Action) -> Void
    let onBack: () -> Void
    @State private var category: Category = .apps
    @Namespace private var tabNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                RoundButton(symbol: "chevron.left", size: 26, help: "Back", action: onBack)
                    .keyboardShortcut(.cancelAction)
                Text(L(replacing == nil ? "Add to Ring" : "Replace Item"))
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 2)
            .padding(.top, 2)

            tabBar

            Group {
                switch category {
                case .apps: AppsList(onPick: onPick)
                case .websites: WebsiteForm(onPick: onPick)
                case .files: FilesPane(onPick: onPick)
                case .shortcuts: ShortcutsList(onPick: onPick)
                case .system: SystemList(onPick: onPick)
                }
            }
            .frame(height: 330, alignment: .top)
            .transition(.opacity)
        }
        .animation(.snappy(duration: 0.25), value: category)
    }

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(Category.allCases, id: \.self) { item in
                let active = category == item
                Button {
                    category = item
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.symbol).font(.system(size: 11, weight: .semibold))
                        Text(L(item.title)).font(.system(size: 9.5, weight: .semibold)).lineLimit(1)
                    }
                    .foregroundStyle(active ? Color.black.opacity(0.78) : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background {
                        if active {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white)
                                .matchedGeometryEffect(id: "tab", in: tabNamespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .glassCard(cornerRadius: 15)
    }
}

// MARK: Rows

private struct PickRow<Icon: View>: View {
    let title: String
    var subtitle: String?
    let action: () -> Void
    @ViewBuilder var icon: Icon
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                icon.frame(width: 26, height: 26)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).font(.system(size: 12)).lineLimit(1)
                    if let subtitle {
                        Text(subtitle).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .opacity(hovering ? 1 : 0)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.primary.opacity(hovering ? 0.08 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct SearchField: View {
    let prompt: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            TextField(L(prompt), text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .glassCapsule()
    }
}

private struct ListCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) { content }
                .padding(5)
        }
        .scrollIndicators(.never)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: Categories

private struct AppsList: View {
    let onPick: (Action) -> Void
    @State private var apps: [InstalledApp] = []
    @State private var query = ""

    private var filtered: [InstalledApp] {
        query.isEmpty ? apps : apps.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 8) {
            SearchField(prompt: "Search apps", text: $query)
            ListCard {
                ForEach(filtered) { app in
                    PickRow(title: app.name, action: { onPick(.app(path: app.path)) }) {
                        Image(nsImage: IconProvider.shared.fileIcon(app.path)).resizable().interpolation(.high)
                    }
                }
                if filtered.isEmpty && !apps.isEmpty {
                    Text(L("No apps found")).font(.system(size: 11)).foregroundStyle(.secondary).padding(20)
                }
            }
        }
        .task {
            if apps.isEmpty { apps = await Task.detached { Catalog.installedApps() }.value }
        }
    }
}

private struct WebsiteForm: View {
    let onPick: (Action) -> Void
    @State private var url = ""
    @State private var name = ""

    private static let suggestions: [(name: String, url: String)] = [
        ("YouTube", "youtube.com"), ("Gmail", "mail.google.com"), ("WhatsApp", "web.whatsapp.com"),
        ("ChatGPT", "chatgpt.com"), ("Claude", "claude.ai"), ("Google Drive", "drive.google.com"),
        ("Instagram", "instagram.com"), ("Netflix", "netflix.com"),
    ]

    private var isValid: Bool {
        let host = URL(string: ActionRunner.normalizedURL(url))?.host ?? ""
        return host.contains(".") || host == "localhost"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 6) {
                field("link", "Address (e.g. github.com)", $url)
                field("textformat", "Name (optional)", $name)
                HStack {
                    Spacer()
                    PillButton(symbol: "plus", title: "Add Site", prominent: isValid) {
                        guard isValid else { return }
                        onPick(.website(url: ActionRunner.normalizedURL(url), name: name.trimmingCharacters(in: .whitespaces)))
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.5)
                }
            }
            .padding(8)
            .glassCard(cornerRadius: 16)

            Text(L("Suggestions").uppercased())
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
            ListCard {
                ForEach(Self.suggestions, id: \.url) { site in
                    let action = Action.website(url: "https://" + site.url, name: site.name)
                    PickRow(title: site.name, subtitle: site.url, action: { onPick(action) }) {
                        ActionIcon(action: action, size: 26)
                    }
                }
            }
        }
    }

    private func field(_ symbol: String, _ prompt: String, _ text: Binding<String>) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).frame(width: 16)
            TextField(L(prompt), text: text).textFieldStyle(.plain).font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Capsule().fill(Color.primary.opacity(0.06)))
    }
}

private struct FilesPane: View {
    let onPick: (Action) -> Void

    private static let places: [(name: String, path: String)] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [("Home", home), ("Desktop", home + "/Desktop"), ("Documents", home + "/Documents"),
                ("Downloads", home + "/Downloads"), ("Applications", "/Applications")]
            .filter { FileManager.default.fileExists(atPath: $0.1) }
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: choose) {
                HStack(spacing: 10) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(L("Choose File or Folder…")).font(.system(size: 12, weight: .semibold))
                        Text(L("Opens with its default app")).font(.system(size: 10.5)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .glassCard(cornerRadius: 16)

            Text(L("Places").uppercased())
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
            ListCard {
                ForEach(Self.places, id: \.path) { place in
                    PickRow(title: L(place.name), subtitle: place.path, action: { onPick(.file(path: place.path)) }) {
                        Image(nsImage: IconProvider.shared.fileIcon(place.path)).resizable().interpolation(.high)
                    }
                }
            }
        }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = L("Add to Ring")
        NSApp.activate(ignoringOtherApps: true)
        // The menu bar panel closes when the open panel takes focus; the pick still lands in the store.
        let onPick = onPick
        panel.begin { response in
            if response == .OK, let url = panel.url {
                onPick(url.pathExtension == "app" ? .app(path: url.path) : .file(path: url.path))
            }
        }
    }
}

private struct ShortcutsList: View {
    let onPick: (Action) -> Void
    @State private var shortcuts: [String]?
    @State private var query = ""

    var body: some View {
        VStack(spacing: 8) {
            SearchField(prompt: "Search shortcuts", text: $query)
            ListCard {
                if let shortcuts {
                    let filtered = query.isEmpty ? shortcuts : shortcuts.filter { $0.localizedCaseInsensitiveContains(query) }
                    ForEach(filtered, id: \.self) { name in
                        PickRow(title: name, action: { onPick(.shortcut(name: name)) }) {
                            ActionIcon(action: .shortcut(name: name), size: 26)
                        }
                    }
                    if shortcuts.isEmpty {
                        Text(L("No shortcuts yet. Create one in the Shortcuts app."))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(20)
                    }
                } else {
                    ProgressView().controlSize(.small).padding(20)
                }
            }
        }
        .task { if shortcuts == nil { shortcuts = await Catalog.shortcuts() } }
    }
}

private struct SystemList: View {
    let onPick: (Action) -> Void

    var body: some View {
        ListCard {
            ForEach(SystemAction.allCases) { item in
                PickRow(title: L(item.title), action: { onPick(.system(item)) }) {
                    ActionIcon(action: .system(item), size: 26)
                }
            }
        }
    }
}
