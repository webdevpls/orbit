import SwiftUI

/// Pages of the menu bar panel.
private enum Page: Equatable {
    case ring
    case picker(replacing: Slot.ID?)
    case settings
}

struct PanelView: View {
    @EnvironmentObject private var store: OrbitStore
    @State private var page: Page = .ring
    @State private var selection: Slot.ID?
    @AppStorage(AppLanguage.key) private var language = "system"

    var body: some View {
        VStack(spacing: 8) {
            switch page {
            case .ring:
                ringPage
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            case .picker(let replacing):
                ActionPicker(replacing: replacing) { action in
                    if let replacing {
                        store.replace(replacing, with: action)
                    } else {
                        store.add(action)
                        selection = store.slots.last?.id
                    }
                    page = .ring
                } onBack: {
                    page = .ring
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .settings:
                SettingsView { page = .ring }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .padding(10)
        .frame(width: 320)
        .background(AmbientBackground())
        .animation(.snappy(duration: 0.3), value: page)
        .id(language)
    }

    private var ringPage: some View {
        VStack(spacing: 8) {
            header
            if !store.accessibilityTrusted { PermissionCard() }
            EditorRing(selection: $selection) { page = .picker(replacing: nil) }
                .padding(.vertical, 4)
            if let id = selection, let slot = store.slots.first(where: { $0.id == id }) {
                SlotCard(slot: slot,
                         onChange: { page = .picker(replacing: id) },
                         onRemove: { withAnimation(.snappy) { store.remove(id); selection = nil } })
            } else {
                hint
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            OrbitMark(size: 18).foregroundStyle(.primary)
            Text("Orbit").font(.system(size: 14, weight: .bold))
            Spacer()
            StatusPill(active: store.accessibilityTrusted && (store.trigger != .off || store.hotkey != .off))
            RoundButton(symbol: "gearshape.fill", size: 26, help: "Settings") { page = .settings }
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private var hint: some View {
        HStack(spacing: 10) {
            Image(systemName: "computermouse.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(triggerSummary).font(.system(size: 12, weight: .semibold))
                Text(L("Click an item to edit it. Hold, point and release to open, or click once and choose."))
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .glassCard(cornerRadius: 16)
    }

    private var triggerSummary: String {
        let parts = [store.trigger == .off ? nil : L(store.trigger.title), store.hotkey == .off ? nil : store.hotkey.title]
            .compactMap { $0 }
        return parts.isEmpty ? L("No trigger set") : parts.joined(separator: " · ")
    }
}

private struct StatusPill: View {
    let active: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(active ? Color.green : Color.orange)
                .frame(width: 6, height: 6)
                .shadow(color: (active ? Color.green : Color.orange).opacity(0.8), radius: 3)
            Text(L(active ? "Active" : "Paused")).font(.system(size: 10.5, weight: .semibold))
        }
        .padding(.horizontal, 9)
        .frame(height: 22)
        .glassCapsule()
    }
}

private struct PermissionCard: View {
    @EnvironmentObject private var store: OrbitStore

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(LinearGradient(colors: [Theme.orange, Theme.pink], startPoint: .top, endPoint: .bottom)))
            VStack(alignment: .leading, spacing: 1) {
                Text(L("Accessibility access needed")).font(.system(size: 12, weight: .semibold))
                Text(L("Lets Orbit see the scroll wheel click."))
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            PillButton(symbol: "checkmark", title: "Allow", prominent: true) { store.requestAccessibility() }
        }
        .padding(10)
        .glassCard(cornerRadius: 16)
    }
}

/// Selected slot details with reorder, change and remove.
private struct SlotCard: View {
    @EnvironmentObject private var store: OrbitStore
    let slot: Slot
    let onChange: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ActionIcon(action: slot.action, size: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text(slot.action.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    HStack(spacing: 4) {
                        Text(L(slot.action.kind))
                        if let index = store.slots.firstIndex(of: slot) {
                            Text("· " + String(format: L("Key %d"), index + 1))
                        }
                        if !slot.action.isAvailable {
                            Text("· " + L("Not found")).foregroundStyle(.orange)
                        }
                    }
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                RoundButton(symbol: "arrow.counterclockwise", size: 26, help: "Move counterclockwise") {
                    withAnimation(.snappy) { store.move(slot.id, by: -1) }
                }
                RoundButton(symbol: "arrow.clockwise", size: 26, help: "Move clockwise") {
                    withAnimation(.snappy) { store.move(slot.id, by: 1) }
                }
            }
            HStack(spacing: 6) {
                PillButton(symbol: "play.fill", title: "Test") { ActionRunner.run(slot.action) }
                Spacer()
                PillButton(symbol: "arrow.triangle.2.circlepath", title: "Change", action: onChange)
                PillButton(symbol: "trash.fill", title: "Remove", destructive: true, action: onRemove)
            }
        }
        .padding(10)
        .glassCard(cornerRadius: 16)
    }
}

/// The ring as an editor: click an icon to select it, the hub adds a new item.
private struct EditorRing: View {
    @EnvironmentObject private var store: OrbitStore
    @Binding var selection: Slot.ID?
    let onAdd: () -> Void
    @State private var hovered: Int?

    private let geometry = RingGeometry(scale: 0.9)

    var body: some View {
        let slots = store.slots
        RingDisc(
            slots: slots,
            geometry: geometry,
            selected: slots.firstIndex { $0.id == selection },
            hovered: hovered,
            onTap: { index in
                let id = slots[index].id
                withAnimation(.snappy(duration: 0.22)) { selection = selection == id ? nil : id }
            },
            onHover: { hovered = $0 }
        ) {
            AddHub(size: geometry.hub, count: slots.count, canAdd: store.canAdd, action: onAdd)
        }
        .frame(width: geometry.disc + 24, height: geometry.disc + 24)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: store.slots)
    }
}

/// Center button of the editor ring.
private struct AddHub: View {
    let size: CGFloat
    let count: Int
    let canAdd: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: canAdd ? "plus" : "checkmark")
                    .font(.system(size: 18, weight: .semibold))
                Text("\(count)/\(OrbitStore.maxSlots)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(hovering && canAdd ? Color.primary : Color.secondary)
            .frame(width: size, height: size)
            .background(HubBackground(highlighted: hovering && canAdd))
            .contentShape(Circle())
            .scaleEffect(hovering && canAdd ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!canAdd)
        .help(L(canAdd ? "Add" : "Full"))
        .onHover { hovering = $0 }
        .animation(.snappy(duration: 0.18), value: hovering)
    }
}
