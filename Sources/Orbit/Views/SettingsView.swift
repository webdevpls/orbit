import SwiftUI

struct SettingsView: View {
    var onBack: () -> Void
    @EnvironmentObject private var store: OrbitStore

    private static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                RoundButton(symbol: "chevron.left", size: 26, help: "Back", action: onBack)
                    .keyboardShortcut(.cancelAction)
                Text(L("Settings"))
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 2)
            .padding(.top, 2)

            section("Open the Ring With") {
                MenuRow(symbol: "computermouse.fill", title: "Mouse Button",
                        options: MouseTrigger.allCases.map { ($0, L($0.title)) }, selection: $store.trigger)
                MenuRow(symbol: "keyboard.fill", title: "Keyboard Shortcut",
                        options: HotkeyChoice.allCases.map { ($0, $0 == .off ? L($0.title) : $0.title) },
                        selection: $store.hotkey)
                SettingRow(symbol: "cursorarrow.click.2", title: "Quick Click Keeps It Open", isOn: $store.clickToKeepOpen)
            }

            section("Appearance") {
                HStack(spacing: 9) {
                    RoundIcon(symbol: "circle.dashed", size: 24)
                    Text(L("Ring Size")).font(.system(size: 12))
                    Spacer()
                    Picker("", selection: $store.ringSize) {
                        ForEach(RingSize.allCases) { Text(L($0.title)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                    .frame(width: 150)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }

            section("General") {
                MenuRow(symbol: "globe", title: "Language",
                        options: AppLanguage.options.map { ($0.code, L($0.name)) },
                        selection: Binding(get: { UserDefaults.standard.string(forKey: AppLanguage.key) ?? "system" },
                                           set: { UserDefaults.standard.set($0, forKey: AppLanguage.key) }))
                SettingRow(symbol: "power.circle.fill", title: "Launch at Login", isOn: $store.launchAtLogin)
                LinkRow(symbol: "hand.raised.fill", title: "Accessibility Permission…", trailing: "arrow.up.right") {
                    store.openAccessibilitySettings()
                }
                LinkRow(symbol: "arrow.uturn.backward", title: "Restore Default Ring", trailing: nil) {
                    withAnimation(.snappy) { store.resetSlots() }
                }
                LinkRow(symbol: "xmark.circle.fill", title: "Quit Orbit", trailing: nil) {
                    NSApp.terminate(nil)
                }
            }

            Text(String(format: L("Orbit %@ · Developed by Vision Tech"), Self.version))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.quaternary)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L(title).uppercased())
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
            VStack(spacing: 2) { content() }
                .padding(6)
                .glassCard(cornerRadius: 16)
        }
    }
}

private struct SettingRow: View {
    let symbol: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 9) {
            RoundIcon(symbol: symbol, size: 24, active: isOn)
            Text(L(title)).font(.system(size: 12))
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle() }
        .animation(.snappy(duration: 0.2), value: isOn)
    }
}

private struct LinkRow: View {
    let symbol: String
    let title: String
    let trailing: String?
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                RoundIcon(symbol: symbol, size: 24)
                Text(L(title)).font(.system(size: 12))
                Spacer()
                if let trailing {
                    Image(systemName: trailing)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.primary.opacity(hovering ? 0.07 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// A row with a pop-up menu of options on the right.
private struct MenuRow<Value: Hashable>: View {
    let symbol: String
    let title: String
    let options: [(Value, String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 9) {
            RoundIcon(symbol: symbol, size: 24)
            Text(L(title)).font(.system(size: 12))
            Spacer()
            Menu {
                ForEach(options, id: \.0) { option in
                    Button {
                        selection = option.0
                    } label: {
                        if option.0 == selection {
                            Label(option.1, systemImage: "checkmark")
                        } else {
                            Text(option.1)
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(options.first { $0.0 == selection }?.1 ?? "")
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 8, weight: .bold))
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}
