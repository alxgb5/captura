import Cocoa
import CoreGraphics

enum CaptureManager {
    static func captureFullscreen() -> NSImage? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }

        let totalBounds = screens.reduce(CGRect.zero) { $0.union($1.frame) }
        let option: CGWindowListOption = PreferencesManager.includeWallpaper ? .optionOnScreenOnly : .optionOnScreenBelowWindow
        guard let image = CGWindowListCreateImage(
            totalBounds,
            option,
            kCGNullWindowID,
            [.bestResolution, .nominalResolution]
        ) else { return nil }

        return NSImage(cgImage: image, size: totalBounds.size)
    }

    static func captureRegion(_ rect: CGRect) -> NSImage? {
        // rect is in NS screen coordinates (y=0 at bottom of primary screen)
        // Convert to CG coordinates (y=0 at top of primary screen)
        let screenHeight = NSScreen.screens.first.map { $0.frame.maxY } ?? NSScreen.main!.frame.height
        let cgRect = CGRect(
            x: rect.origin.x,
            y: screenHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        let option: CGWindowListOption = PreferencesManager.includeWallpaper ? .optionOnScreenOnly : .optionOnScreenBelowWindow
        guard let image = CGWindowListCreateImage(
            cgRect,
            option,
            kCGNullWindowID,
            [.bestResolution, .nominalResolution]
        ) else { return nil }

        return NSImage(cgImage: image, size: rect.size)
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
