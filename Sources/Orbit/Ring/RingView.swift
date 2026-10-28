import SwiftUI

/// The floating ring shown at the pointer.
struct RingView: View {
    @EnvironmentObject private var ring: RingController

    var body: some View {
        let g = ring.geometry
        let count = ring.slots.count

        ZStack {
            // A faint shade under the ring keeps it readable over busy windows.
            Circle()
                .fill(RadialGradient(colors: [.black.opacity(0.16), .clear], center: .center,
                                     startRadius: g.radius * 0.4, endRadius: g.outerRadius + 24))
                .opacity(ring.presented ? 1 : 0)

            GlassGroup(spacing: 22 * g.scale) {
                ZStack {
                    ForEach(Array(ring.slots.enumerated()), id: \.element.id) { index, slot in
                        let isSelected = ring.selected == index
                        RingBubble(action: slot.action, size: g.bubble, selected: isSelected, firing: ring.firing == index)
                            .scaleEffect(ring.presented ? (isSelected ? 1.16 : 1) : 0.3)
                            .offset(ring.presented ? g.offset(index, of: count) : .zero)
                            .opacity(ring.presented ? 1 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.72)
                                .delay(ring.presented ? Double(index) * 0.014 : 0), value: ring.presented)
                    }

                    RingHub(
                        title: ring.selected.flatMap { ring.slots.indices.contains($0) ? ring.slots[$0].action.title : nil },
                        pointer: ring.selected.map { g.angle($0, of: count) },
                        empty: ring.slots.isEmpty,
                        size: g.hub
                    )
                    .scaleEffect(ring.presented ? 1 : 0.6)
                    .opacity(ring.presented ? 1 : 0)
                }
            }
        }
        .frame(width: g.canvas, height: g.canvas)
    }
}

/// One app/action bubble.
struct RingBubble: View {
    let action: Action
    var size: CGFloat
    var selected = false
    var firing = false

    var body: some View {
        ActionIcon(action: action, size: size * 0.64)
            .saturation(action.isAvailable ? 1 : 0)
            .opacity(action.isAvailable ? 1 : 0.45)
            .frame(width: size, height: size)
            .glassCircle(tint: selected ? Color.white.opacity(0.3) : nil)
            .overlay(Circle().strokeBorder(Color.white.opacity(selected ? 0.75 : 0), lineWidth: 1.5))
            .shadow(color: .black.opacity(selected ? 0.32 : 0.14), radius: selected ? 12 : 5, y: 3)
            .scaleEffect(firing ? 1.22 : 1)
    }
}

/// Center of the ring: shows the selected item's name and points toward it.
struct RingHub: View {
    var title: String?
    var pointer: CGFloat?
    var empty = false
    var size: CGFloat

    var body: some View {
        ZStack {
            if let title {
                Text(title)
                    .font(.system(size: 11.5 * size / 84, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, size * 0.14)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .id(title)
            } else if empty {
                Text(L("Add apps in the menu bar"))
                    .font(.system(size: 9.5 * size / 84, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, size * 0.12)
            } else {
                OrbitMark(size: size * 0.32)
                    .foregroundStyle(.tertiary)
                    .transition(.opacity)
            }

            if let pointer {
                // Short arc on the rim facing the selected bubble.
                Circle()
                    .trim(from: 0, to: 0.12)
                    .stroke(Color.primary.opacity(0.7), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .padding(4)
                    .rotationEffect(.radians(pointer - 0.06 * 2 * .pi))
                    .transition(.opacity)
            }
        }
        .frame(width: size, height: size)
        .glassCircle()
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        .animation(.snappy(duration: 0.18), value: title)
    }
}
