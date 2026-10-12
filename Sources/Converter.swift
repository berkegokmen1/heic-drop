import AppKit
import ImageIO
import UniformTypeIdentifiers

enum OutputFormat: String { case png, jpg
    var type: CFString { (self == .png ? UTType.png.identifier : UTType.jpeg.identifier) as CFString }
}
enum ConversionError: LocalizedError {
    case unreadable, writeFailed
    var errorDescription: String? { self == .unreadable ? "Could not read this image." : "Could not write the converted image." }
}
struct Converter {
    static func convert(_ input: URL, to output: URL, format: OutputFormat) throws {
        guard let source = CGImageSourceCreateWithURL(input as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw ConversionError.unreadable }
        var rendered = image
        if format == .jpg {
            guard let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { throw ConversionError.writeFailed }
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            guard let flattened = context.makeImage() else { throw ConversionError.writeFailed }; rendered = flattened
        }
        guard let destination = CGImageDestinationCreateWithURL(output as CFURL, format.type, 1, nil) else { throw ConversionError.writeFailed }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
        var settings: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.95]
        if let orientation = properties[kCGImagePropertyOrientation] { settings[kCGImagePropertyOrientation] = orientation }
        CGImageDestinationAddImage(destination, rendered, settings as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ConversionError.writeFailed }
    }
    static func uniqueURL(in directory: URL, name: String, format: OutputFormat) -> URL {
        var index = 1
        var url = directory.appendingPathComponent(name).appendingPathExtension(format.rawValue)
        while FileManager.default.fileExists(atPath: url.path) {
            index += 1; url = directory.appendingPathComponent("\(name) \(index)").appendingPathExtension(format.rawValue)
        }
        return url
    }
}
