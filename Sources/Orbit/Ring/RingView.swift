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

    var body: some View {
        let g = geometry
        let count = slots.count

        ZStack {
            // The disc.
            Circle()
                .fill(Color.clear)
                .frame(width: g.disc, height: g.disc)
                .glassCircle()
                .overlay(
                    Circle().strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.08), .white.opacity(0.2)],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.22), radius: 22 * g.scale, y: 10 * g.scale)

            // Faint orbit line the icons sit on.
            Circle()
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                .frame(width: g.radius * 2, height: g.radius * 2)

            // Selection lens.
            GlassLens(size: g.lens, firing: firing != nil)
                .modifier(ArcPosition(angle: lensAngle, radius: g.radius))
                .opacity(lensVisible ? 1 : 0)
                .scaleEffect(lensVisible ? 1 : 0.6)

            ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                let isSelected = selected == index
                let emphasis: CGFloat = isSelected ? (firing == index ? 1.24 : 1.14) : (hovered == index ? 1.07 : 1)
                ActionIcon(action: slot.action, size: g.icon)
                    .saturation(slot.action.isAvailable ? 1 : 0)
                    .opacity(slot.action.isAvailable ? 1 : 0.45)
                    .shadow(color: .black.opacity(0.22), radius: 3, y: 1.5)
                    .frame(width: g.lens, height: g.lens)
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

/// The bright glass bead behind the selected icon.
private struct GlassLens: View {
    var size: CGFloat
    var firing = false

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [.white.opacity(0.42), .white.opacity(0.14)], startPoint: .top, endPoint: .bottom))
            .overlay(
                Circle().strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.95), .white.opacity(0.2), .white.opacity(0.5)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.2)
            )
            .overlay(
                // Specular highlight.
                Ellipse()
                    .fill(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .scaleEffect(x: 0.62, y: 0.32)
                    .offset(y: -0.24 * size)
                    .blur(radius: 1)
            )
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .scaleEffect(firing ? 1.12 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: firing)
    }
}

/// Center of the floating ring: the selected item's name.
struct RingLabel: View {
    var title: String?
    var empty = false
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.05))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))

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
