import Cocoa
import CoreGraphics

class ScrollingCaptureManager: NSObject {
    private var overlayWindow: NSWindow?
    private var overlayController: ScrollingCaptureOverlayController?
    private var scrollTimer: Timer?
    var onComplete: ((NSImage) -> Void)?

    func start() {
        overlayWindow?.close()
        overlayController = ScrollingCaptureOverlayController()
        overlayController?.onTargetSelected = { [weak self] location in
            self?.captureScrollableArea(at: location)
        }
        overlayController?.show()
    }

    private func captureScrollableArea(at targetLocation: CGPoint) {
        overlayWindow?.close()

        var screenshots: [NSImage] = []
        let scrollInterval: TimeInterval = 0.3

        // Start with initial screenshot
        if let image = CaptureManager.captureFullscreen() {
            screenshots.append(image)
        }

        self.scrollTimer = Timer.scheduledTimer(withTimeInterval: scrollInterval, repeats: true) { [weak self] timer in
            // Simulate scroll wheel event at target location
            let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: -5, wheel2: 0, wheel3: 0)
            scrollEvent?.location = targetLocation
            scrollEvent?.post(tap: .cghidEventTap)

            // Capture after scroll
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let image = CaptureManager.captureFullscreen() {
                    screenshots.append(image)
                }

                // Stop after 20 scrolls (reasonable limit)
                if screenshots.count > 20 {
                    timer.invalidate()
                    self?.scrollTimer = nil

                    // Stitch images
                    if let stitched = self?.stitchImages(screenshots) {
                        self?.onComplete?(stitched)
                    }
                }
            }
        }
    }

    private func stitchImages(_ images: [NSImage]) -> NSImage? {
        guard !images.isEmpty else { return nil }

        let baseSize = images[0].size
        let totalHeight = images.reduce(0) { $0 + $1.size.height }
        let stitchedSize = NSSize(width: baseSize.width, height: totalHeight)

        guard let stitchedRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(stitchedSize.width),
            pixelsHigh: Int(stitchedSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        let context = NSGraphicsContext(bitmapImageRep: stitchedRep)
        NSGraphicsContext.current = context

        var yOffset: CGFloat = 0
        for image in images {
            let rect = NSRect(x: 0, y: yOffset, width: image.size.width, height: image.size.height)
            image.draw(in: rect)
            yOffset += image.size.height
        }

        NSGraphicsContext.current = nil

        let result = NSImage(size: stitchedSize)
        result.addRepresentation(stitchedRep)
        return result
    }
}

class ScrollingCaptureOverlayController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    var onTargetSelected: ((CGPoint) -> Void)?

    func show() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let win = NSWindow(
            contentRect: screen.visibleFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.level = .floating
        win.isOpaque = false
        win.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        win.delegate = self

        let contentView = ScrollingCaptureOverlayView(frame: screen.visibleFrame)
        contentView.onLocationClick = { [weak self] location in
            self?.onTargetSelected?(location)
            win.close()
        }
        win.contentView = contentView

        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() { window?.close() }
    func windowWillClose(_ notification: Notification) { }
}

class ScrollingCaptureOverlayView: NSView {
    var onLocationClick: ((CGPoint) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let text = NSAttributedString(
            string: "Click on the scrollable area to start",
            attributes: [
                .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: NSColor.white
            ]
        )
        let textSize = text.size()
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect)
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, to: nil)
        onLocationClick?(location)
    }
}
