import AppKit
let root = CommandLine.arguments[1]
for size in [16, 32, 64, 128, 256, 512, 1024] {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = CGFloat(size) / 1024
    let transform = NSAffineTransform(); transform.scale(by: scale); transform.concat()
    NSColor(calibratedRed: 0.08, green: 0.12, blue: 0.18, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 48, y: 48, width: 928, height: 928), xRadius: 210, yRadius: 210).fill()
    NSColor.white.setFill()
    NSBezierPath(roundedRect: NSRect(x: 225, y: 300, width: 574, height: 440), xRadius: 48, yRadius: 48).fill()
    NSColor(calibratedRed: 0.20, green: 0.85, blue: 0.60, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 310, y: 565, width: 90, height: 90)).fill()
    let mountain = NSBezierPath(); mountain.move(to: NSPoint(x: 270, y: 350)); mountain.line(to: NSPoint(x: 465, y: 570)); mountain.line(to: NSPoint(x: 580, y: 445)); mountain.line(to: NSPoint(x: 680, y: 550)); mountain.line(to: NSPoint(x: 760, y: 350)); mountain.close(); mountain.fill()
    NSGraphicsContext.restoreGraphicsState()
    let data = bitmap.representation(using: .png, properties: [:])!
    let names: [Int: [String]] = [16:["icon_16x16"],32:["icon_16x16@2x","icon_32x32"],64:["icon_32x32@2x"],128:["icon_128x128"],256:["icon_128x128@2x","icon_256x256"],512:["icon_256x256@2x","icon_512x512"],1024:["icon_512x512@2x"]]
    for name in names[size]! { try data.write(to: URL(fileURLWithPath: root).appendingPathComponent(name + ".png")) }
}
