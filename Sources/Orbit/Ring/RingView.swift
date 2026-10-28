import SwiftUI

/// The floating ring shown at the pointer.
struct RingView: View {
    @EnvironmentObject private var ring: RingController

    var body: some View {
        let g = ring.geometry
        RingDisc(slots: ring.slots, geometry: g, selected: ring.selected, firing: ring.firing, presented: ring.presented) {
            RingLabel(
                title: ring.selected.flatMap { ring.slots.indices.contains($0) ? ring.slots[$0].action.title : nil },
                empty: ring.slots.isEmpty,
                size: g.hub
            )
        }
        .frame(width: g.canvas, height: g.canvas)
    }
}

/// A single glass disc with the icons on it and a glass lens that glides to the selected one.
/// Shared by the floating ring and the editor in the menu bar panel.
struct RingDisc<Hub: View>: View {
    let slots: [Slot]
    let geometry: RingGeometry
    var selected: Int?
    var firing: Int?
    var presented = true
    var hovered: Int?
    var onTap: ((Int) -> Void)?
    var onHover: ((Int?) -> Void)?
    @ViewBuilder var hub: Hub

    /// Unwrapped lens angle, so it always takes the short way around.
    @State private var lensAngle: CGFloat = -.pi / 2
    @State private var lensVisible = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var icons = IconProvider.shared

    private var glowColor: Color {
        guard let selected, slots.indices.contains(selected) else { return .clear }
        return icons.tint(for: slots[selected].action)
    }

    var body: some View {
        let g = geometry
        let count = slots.count

        ZStack {
            // Soft shadow, drawn on its own: a shadow on the glass itself renders as a square.
            Circle()
                .fill(Color.black.opacity(0.28))
                .frame(width: g.disc * 0.92, height: g.disc * 0.92)
                .blur(radius: 22 * g.scale)
                .offset(y: 12 * g.scale)
                .allowsHitTesting(false)

            // Frosted glass disc.
            Circle()
                .fill(Color.clear)
                .frame(width: g.disc, height: g.disc)
                .glassCircle()

            // Colored light drifting inside the glass, strongest along the icon track.
            Aurora(paused: !presented)
                .frame(width: g.disc, height: g.disc)
                // A radial gradient fades the light in a ring around the track (a blurred mask renders square).
                .mask(
                    RadialGradient(stops: [
                        .init(color: .clear, location: 0.42),
                        .init(color: .white, location: 0.68),
                        .init(color: .white, location: 0.8),
                        .init(color: .clear, location: 1),
                    ], center: .center, startRadius: 0, endRadius: g.disc / 2)
                )
                .opacity(colorScheme == .dark ? 0.5 : 0.38)
                .allowsHitTesting(false)

            // Sheen and bright rim: the glassmorphism edge.
            Circle()
                .fill(LinearGradient(colors: [.white.opacity(0.16), .white.opacity(0)], startPoint: .top, endPoint: .center))
                .frame(width: g.disc, height: g.disc)
                .overlay(
                    Circle().strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0.1), .white.opacity(0.35)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.2)
                )
                .allowsHitTesting(false)

            // Glow in the selected app's color, gliding along the ring.
            Circle()
                .fill(glowColor)
                .frame(width: g.lens * 1.3, height: g.lens * 1.3)
                .blur(radius: 16 * g.scale)
                .modifier(ArcPosition(angle: lensAngle, radius: g.radius))
                .opacity(lensVisible ? (firing != nil ? 1 : 0.8) : 0)
                .scaleEffect(lensVisible ? 1 : 0.5)
                .allowsHitTesting(false)

            ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                let isSelected = selected == index
                let emphasis: CGFloat = isSelected ? (firing == index ? 1.22 : 1.12) : (hovered == index ? 1.06 : 1)
                GlassTile(size: g.lens * 0.94, lit: isSelected || hovered == index) {
                    ActionIcon(action: slot.action, size: g.icon)
                        .saturation(slot.action.isAvailable ? 1 : 0)
                        .opacity(slot.action.isAvailable ? 1 : 0.45)
                        .shadow(color: .black.opacity(0.25), radius: 3, y: 1.5)
                }
                .contentShape(Circle())
                .scaleEffect(presented ? emphasis : 0.4)
                .opacity(presented ? 1 : 0)
                .offset(presented ? g.offset(index, of: count) : .zero)
                .animation(.spring(response: 0.42, dampingFraction: 0.78)
                    .delay(presented ? Double(index) * 0.018 : 0), value: presented)
                .animation(.spring(response: 0.28, dampingFraction: 0.68), value: emphasis)
                .onTapGesture { onTap?(index) }
                .onHover { inside in onHover?(inside ? index : (hovered == index ? nil : hovered)) }
                .help(onTap == nil ? "" : slot.action.title)
            }

            hub
        }
        .scaleEffect(presented ? 1 : 0.86)
        .opacity(presented ? 1 : 0)
        .onAppear { moveLens(to: selected, count: count, animated: false) }
        .onChange(of: selected) { _, new in moveLens(to: new, count: count, animated: true) }
        .onChange(of: count) { _, new in moveLens(to: selected, count: new, animated: true) }
    }

    private func moveLens(to index: Int?, count: Int, animated: Bool) {
        guard let index, count > 0 else {
            withAnimation(.easeOut(duration: 0.15)) { lensVisible = false }
            return
        }
        let target = geometry.angle(index, of: count)
        var delta = (target - lensAngle).truncatingRemainder(dividingBy: 2 * .pi)
        if delta > .pi { delta -= 2 * .pi }
        if delta < -.pi { delta += 2 * .pi }

        if !lensVisible || !animated {
            // Appear in place instead of sliding in from a stale position.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { lensAngle = target }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { lensVisible = true }
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) { lensAngle += delta }
        }
    }
}

/// Places a view on a circle; animating the angle moves it along the arc instead of across.
private struct ArcPosition: ViewModifier, Animatable {
    var angle: CGFloat
    var radius: CGFloat

    var animatableData: CGFloat {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        content.offset(x: radius * cos(angle), y: radius * sin(angle))
    }
}

/// Frosted glass tile under each icon; brighter when lit.
private struct GlassTile<Content: View>: View {
    var size: CGFloat
    var lit = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(lit ? 0.4 : 0.16), .white.opacity(lit ? 0.12 : 0.03)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(
                        Circle().strokeBorder(
                            LinearGradient(colors: [.white.opacity(lit ? 0.95 : 0.5), .white.opacity(lit ? 0.25 : 0.06)],
                                           startPoint: .top, endPoint: .bottom),
                            lineWidth: lit ? 1.2 : 0.8)
                    )
                    .shadow(color: .black.opacity(lit ? 0.22 : 0.1), radius: lit ? 8 : 3, y: lit ? 4 : 1.5)
            )
            .animation(.snappy(duration: 0.2), value: lit)
    }
}

/// Slowly turning multicolor light.
private struct Aurora: View {
    var paused = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: paused)) { context in
            let angle = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 24) / 24 * 360
            AngularGradient(colors: [Theme.violet, Theme.blue, Theme.teal, Theme.pink, Theme.orange, Theme.violet],
                            center: .center, angle: .degrees(angle))
        }
    }
}

/// Center of the floating ring: the selected item's name.
struct RingLabel: View {
    var title: String?
    var empty = false
    var size: CGFloat

    var body: some View {
        ZStack {
            HubBackground()

            if let title {
                Text(title)
                    .font(.system(size: 12.5 * size / 86, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, size * 0.13)
                    .id(title)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.92)), removal: .opacity))
            } else if empty {
                Text(L("Add apps in the menu bar"))
                    .font(.system(size: 9.5 * size / 86, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, size * 0.12)
            } else {
                OrbitMark(size: size * 0.3)
                    .foregroundStyle(.tertiary)
                    .transition(.opacity)
            }
        }
        .frame(width: size, height: size)
        .animation(.snappy(duration: 0.16), value: title)
    }
}

/// Frosted center disc with a bright rim, shared by the ring and the editor.
struct HubBackground: View {
    var highlighted = false

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [.white.opacity(highlighted ? 0.24 : 0.12), .white.opacity(0.02)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(
                Circle().strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}
