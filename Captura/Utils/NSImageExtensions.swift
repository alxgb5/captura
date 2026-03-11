import Cocoa

extension NSImage {
    static func renderSymbol(_ symbolName: String, size: CGFloat = 16, color: NSColor = .white) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular, scale: .medium)
        guard let baseImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
            return NSImage()
        }

        let image = baseImage.withSymbolConfiguration(config) ?? baseImage
        let rect = NSRect(x: 0, y: 0, width: size, height: size)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size),
            pixelsHigh: Int(size),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return image }

        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context

        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

        NSGraphicsContext.current = nil

        let result = NSImage(size: NSSize(width: size, height: size))
        result.addRepresentation(rep)
        return result
    }
}
