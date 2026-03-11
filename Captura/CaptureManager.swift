import Cocoa
import CoreGraphics

enum CaptureManager {
    static func captureFullscreen() -> NSImage? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }

        // Capture all screens combined into one image
        let totalBounds = screens.reduce(CGRect.zero) { $0.union($1.frame) }
        guard let image = CGWindowListCreateImage(
            totalBounds,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .nominalResolution]
        ) else { return nil }

        return NSImage(cgImage: image, size: totalBounds.size)
    }

    static func captureRegion(_ rect: CGRect) -> NSImage? {
        // rect is in screen coordinates (bottom-left origin from CGDisplay)
        // NSScreen uses flipped coordinates; convert to CG coordinates
        let screenHeight = NSScreen.screens.first.map { $0.frame.maxY } ?? NSScreen.main!.frame.height
        let cgRect = CGRect(
            x: rect.origin.x,
            y: screenHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        guard let image = CGWindowListCreateImage(
            cgRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .nominalResolution]
        ) else { return nil }

        return NSImage(cgImage: image, size: rect.size)
    }
}
