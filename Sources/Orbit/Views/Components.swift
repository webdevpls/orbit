import SwiftUI

enum Theme {
    static let violet = Color(red: 0.56, green: 0.46, blue: 1.0)
    static let blue = Color(red: 0.27, green: 0.6, blue: 1.0)
    static let teal = Color(red: 0.3, green: 0.84, blue: 0.86)
    static let pink = Color(red: 1.0, green: 0.43, blue: 0.69)
    static let orange = Color(red: 1.0, green: 0.62, blue: 0.32)

    static func rgb(_ hex: UInt32) -> Color {
        Color(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    /// Soft gradient tiles for actions drawn with SF Symbols.
    static func symbolColors(for action: Action) -> [Color] {
        let pair: (UInt32, UInt32)
        switch action {
        case .system(.screenshot): pair = (0x9DA8C4, 0x5C6680)
        case .system(.missionControl): pair = (0x6F8CFF, 0x4C5BD8)
        case .system(.apps): pair = (0xF56BD8, 0x9B6BFF)
        case .system(.lockScreen): pair = (0x5A6274, 0x2E3340)
        case .system(.sleepDisplay): pair = (0x6A5AE0, 0x2F2C86)
        case .system(.emoji): pair = (0xF7C25A, 0xE8833F)
        case .system(.desktop): pair = (0x4FD4FF, 0x3A7BFF)
        case .website: pair = (0x4FD4FF, 0x3A7BFF)
        default: pair = (0x9AA0AE, 0x5C6270)
        }
        return [rgb(pair.0), rgb(pair.1)]
    }
}

/// Soft colored light behind the glass panels.
struct AmbientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let strength = colorScheme == .dark ? 0.12 : 0.07
        ZStack {
            // A light base tint keeps the glass legible over bright windows.
            Rectangle().fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.35))

            ZStack {
                Circle().fill(Theme.violet).frame(width: 220).offset(x: -110, y: -170)
                Circle().fill(Theme.teal).frame(width: 200).offset(x: 120, y: 30)
                Circle().fill(Theme.pink).frame(width: 180).offset(x: -60, y: 220)
            }
            .opacity(strength)
            .blur(radius: 70)
        }
        .allowsHitTesting(false)
    }
}

/// Small circular glass icon button.
struct RoundButton: View {
    let symbol: String
    var size: CGFloat = 26
    var active = false
    var help: String = ""
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            RoundIcon(symbol: symbol, size: size, active: active, hovering: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(L(help))
    }
}

struct RoundIcon: View {
    let symbol: String
    var size: CGFloat = 26
    var active = false
    var hovering = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(active ? Color.black.opacity(0.75) : (hovering ? Color.primary : Color.secondary))
            .frame(width: size, height: size)
            .background {
                if active {
                    Circle().fill(Color.white)
                } else {
                    Circle().fill(Color.primary.opacity(hovering ? 0.13 : 0.07))
                }
            }
            .contentShape(Circle())
    }
}

/// Capsule glass button with an icon and a label.
struct PillButton: View {
    let symbol: String
    let title: String
    var prominent = false
    var destructive = false
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 10, weight: .bold))
                Text(L(title)).font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(prominent ? Color.black.opacity(0.78) : (destructive ? Color.red : Color.primary))
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background {
                Capsule().fill(prominent ? Color.white : Color.primary.opacity(hovering ? 0.13 : 0.07))
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// The Orbit mark: eight dots around a hub. Used in the menu bar and the ring's empty hub.
struct OrbitMark: View {
    var size: CGFloat = 18
    var lineWidth: CGFloat? = nil

    var body: some View {
        Canvas { context, canvas in
            let s = canvas.width
            let c = CGPoint(x: s / 2, y: s / 2)
            let r = s * 0.38
            let dot = s * 0.15
            for i in 0..<8 {
                let a = Double(i) / 8 * 2 * .pi - .pi / 2
                let p = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
                context.fill(Path(ellipseIn: CGRect(x: p.x - dot / 2, y: p.y - dot / 2, width: dot, height: dot)),
                             with: .foreground)
            }
            let hub = s * 0.3
            context.stroke(Path(ellipseIn: CGRect(x: c.x - hub / 2, y: c.y - hub / 2, width: hub, height: hub)),
                           with: .foreground, lineWidth: lineWidth ?? s * 0.08)
        }
        .frame(width: size, height: size)
    }
}

extension View {
    /// Liquid Glass card on macOS 26, translucent card on earlier systems.
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            fallbackGlass(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        #else
        fallbackGlass(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        #endif
    }

    /// Liquid Glass circle, optionally tinted, on macOS 26; material circle before.
    @ViewBuilder
    func glassCircle(tint: Color? = nil) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            glassEffect(tint.map { Glass.regular.tint($0) } ?? .regular, in: .circle)
        } else {
            fallbackGlass(Circle(), tint: tint)
        }
        #else
        fallbackGlass(Circle(), tint: tint)
        #endif
    }

    @ViewBuilder
    func glassCapsule() -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: .capsule)
        } else {
            fallbackGlass(Capsule())
        }
        #else
        fallbackGlass(Capsule())
        #endif
    }

    private func fallbackGlass<S: InsettableShape>(_ shape: S, tint: Color? = nil) -> some View {
        background(
            shape.fill(.ultraThinMaterial)
                .overlay(shape.fill(tint ?? .clear))
                .overlay(
                    shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.05)],
                                                      startPoint: .top, endPoint: .bottom), lineWidth: 0.75)
                )
        )
    }
}
