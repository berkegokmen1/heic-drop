import AppKit
import ImageIO
import UniformTypeIdentifiers
let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: root) }
let context = CGContext(data: nil, width: 32, height: 24, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 16, height: 24))
let image = context.makeImage()!
func fixture(_ type: UTType, name: String) -> URL {
    let url = root.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, [kCGImagePropertyOrientation: 6] as CFDictionary)
    precondition(CGImageDestinationFinalize(dest)); return url
}
let heic = fixture(.heic, name: "sample.heic")
for format in [OutputFormat.png, .jpg] {
    let output = Converter.uniqueURL(in: root, name: "sample", format: format)
    try Converter.convert(heic, to: output, format: format)
    let source = CGImageSourceCreateWithURL(output as CFURL, nil)!
    precondition(CGImageSourceGetType(source)! as String == (format == .png ? UTType.png.identifier : UTType.jpeg.identifier))
    let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)! as NSDictionary
    precondition(properties[kCGImagePropertyPixelWidth] as! Int == 32)
    precondition(properties[kCGImagePropertyPixelHeight] as! Int == 24)
    precondition(properties[kCGImagePropertyOrientation] as! Int == 6)
    precondition(Converter.uniqueURL(in: root, name: "sample", format: format) != output)
}
let transparent = fixture(.png, name: "transparent.png")
let jpg = root.appendingPathComponent("flattened.jpg")
try Converter.convert(transparent, to: jpg, format: .jpg)
let decoded = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(jpg as CFURL, nil)!, 0, nil)!
let pixels = CGContext(data: nil, width: 32, height: 24, bitsPerComponent: 8, bytesPerRow: 128, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
pixels.draw(decoded, in: CGRect(x: 0, y: 0, width: 32, height: 24))
let bytes = pixels.data!.assumingMemoryBound(to: UInt8.self)
let offset = (12 * 32 + 28) * 4
precondition(bytes[offset] > 240 && bytes[offset+1] > 240 && bytes[offset+2] > 240)
let bad = root.appendingPathComponent("bad.heic"); try Data("invalid".utf8).write(to: bad)
do { try Converter.convert(bad, to: root.appendingPathComponent("bad.png"), format: .png); fatalError("Invalid input accepted") } catch {}
print("PASS: HEIC to PNG/JPG, dimensions, orientation, unique names, transparency, invalid input")
