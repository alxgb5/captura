import Cocoa
import CoreGraphics

enum CaptureManager {
    static func captureFullscreen() -> NSImage? {
        let displayID = CGMainDisplayID()
        guard let cgImage = CGDisplayCreateImage(displayID) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    static func captureRegion(_ rect: CGRect) -> NSImage? {
        // rect is in NS screen coordinates (y=0 at bottom of primary screen)
        let displayID = CGMainDisplayID()
        guard let fullImage = CGDisplayCreateImage(displayID) else { return nil }

        let screenHeight = CGFloat(CGDisplayPixelsHigh(displayID))
        let scale = CGFloat(fullImage.height) / screenHeight
        let imageRect = CGRect(
            x: rect.origin.x * scale,
            y: (screenHeight - rect.origin.y - rect.height) * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )

        guard let cropped = fullImage.cropping(to: imageRect) else { return nil }
        return NSImage(cgImage: cropped, size: rect.size)
    }

    static func captureWindow(_ info: WindowInfo) -> NSImage? {
        guard let image = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            info.windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else { return nil }

        return NSImage(cgImage: image, size: info.bounds.size)
    }
}
