// Renders Resources/AppIcon.icns and Resources/AppIcon.png: eight glass orbs around a hub.
// Run from the repo root: `swift scripts/make-icon.swift`.
import AppKit

func png(_ cg: CGImage, size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSGraphicsContext.current?.cgContext.draw(cg, in: CGRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

/// A glossy sphere: colored gradient body, soft top highlight, thin rim.
func orb(center: NSPoint, radius: CGFloat, top: NSColor, bottom: NSColor) {
    let rect = NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    let path = NSBezierPath(ovalIn: rect)

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
    shadow.shadowBlurRadius = radius * 0.35
    shadow.shadowOffset = NSSize(width: 0, height: -radius * 0.15)
    shadow.set()
    bottom.setFill()
    path.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.current?.saveGraphicsState()
    path.addClip()
    NSGradient(colors: [top, bottom])!.draw(in: rect, angle: -90)
    let shine = NSRect(x: rect.minX + radius * 0.25, y: rect.midY + radius * 0.05, width: radius * 1.5, height: radius * 0.85)
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.7), NSColor.white.withAlphaComponent(0)])!
        .draw(in: NSBezierPath(ovalIn: shine), angle: -90)
    NSGraphicsContext.current?.restoreGraphicsState()

    path.lineWidth = radius * 0.06
    NSColor.white.withAlphaComponent(0.45).setStroke()
    path.stroke()
}

let size: CGFloat = 1024
let icon = NSImage(size: NSSize(width: size, height: size))
icon.lockFocus()
let rect = NSRect(x: 100, y: 100, width: 824, height: 824)
let squircle = NSBezierPath(roundedRect: rect, xRadius: 186, yRadius: 186)

NSGraphicsContext.current?.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.set()
NSColor.black.setFill()
squircle.fill()
NSGraphicsContext.current?.restoreGraphicsState()

NSGraphicsContext.current?.saveGraphicsState()
squircle.addClip()
NSGradient(colors: [color(0x12162A), color(0x1D2442)])!.draw(in: rect, angle: -90)
NSGradient(colors: [color(0x8F75FF, 0.4), .clear])!
    .draw(fromCenter: NSPoint(x: 512, y: 512), radius: 0, toCenter: NSPoint(x: 512, y: 512), radius: 430, options: [])
NSGradient(colors: [NSColor.white.withAlphaComponent(0.12), NSColor.white.withAlphaComponent(0)])!
    .draw(in: NSRect(x: 100, y: 512, width: 824, height: 412), angle: -90)

let palette: [(UInt32, UInt32)] = [
    (0x6FD8FF, 0x3A7BFF), (0x9B8CFF, 0x5E46F0), (0xF79BE8, 0xB45CFF), (0xFF9EB5, 0xFF5F7E),
    (0xFFC27A, 0xFF7A45), (0xFFE68A, 0xF2A93B), (0x9BF0B4, 0x2FBF8A), (0x8FF0F0, 0x2BB5C8),
]
let center = NSPoint(x: 512, y: 512)
for (i, colors) in palette.enumerated() {
    let a = CGFloat.pi / 2 - CGFloat(i) / 8 * 2 * .pi
    orb(center: NSPoint(x: center.x + 250 * cos(a), y: center.y + 250 * sin(a)), radius: 70,
        top: color(colors.0), bottom: color(colors.1))
}

// Frosted hub.
let hubRect = NSRect(x: 512 - 120, y: 512 - 120, width: 240, height: 240)
let hub = NSBezierPath(ovalIn: hubRect)
NSGradient(colors: [NSColor.white.withAlphaComponent(0.32), NSColor.white.withAlphaComponent(0.1)])!.draw(in: hub, angle: -90)
hub.lineWidth = 6
NSColor.white.withAlphaComponent(0.55).setStroke()
hub.stroke()
let arc = NSBezierPath()
arc.appendArc(withCenter: center, radius: 96, startAngle: 68, endAngle: 112)
arc.lineWidth = 16
arc.lineCapStyle = .round
NSColor.white.withAlphaComponent(0.9).setStroke()
arc.stroke()
NSGraphicsContext.current?.restoreGraphicsState()
icon.unlockFocus()

let fm = FileManager.default
let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? fm.removeItem(at: iconset)
try! fm.createDirectory(at: iconset, withIntermediateDirectories: true)
let cg = icon.cgImage(forProposedRect: nil, context: nil, hints: nil)!
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! png(cg, size: base * scale).write(to: iconset.appendingPathComponent(name))
    }
}
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! task.run()
task.waitUntilExit()
try! png(cg, size: 1024).write(to: URL(fileURLWithPath: "Resources/AppIcon.png"))
print("Wrote Resources/AppIcon.icns and Resources/AppIcon.png")
