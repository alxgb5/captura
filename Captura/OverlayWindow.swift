import Cocoa

class OverlayWindowController: NSObject {
    var onCapture: ((CGRect) -> Void)?
    private var windows: [NSWindow] = []

    func show() {
        // Create a fullscreen overlay on each screen
        for screen in NSScreen.screens {
            let window = OverlayWindow(screen: screen)
            window.overlayController = self
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }

    func didSelectRect(_ rect: CGRect) {
        onCapture?(rect)
    }
}

class OverlayWindow: NSWindow {
    weak var overlayController: OverlayWindowController?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        level = .screenSaver
        backgroundColor = NSColor.black.withAlphaComponent(0.3)
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = OverlayView(frame: screen.frame)
        view.overlayWindow = self
        contentView = view
    }

    func reportRect(_ rect: CGRect) {
        overlayController?.didSelectRect(rect)
    }

    override var canBecomeKey: Bool { true }
}

class OverlayView: NSView {
    weak var overlayWindow: OverlayWindow?
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var isDragging = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        // crosshair cursor
    }
    required init?(coder: NSCoder) { fatalError() }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        isDragging = true
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isDragging, let start = startPoint else { return }
        let end = convert(event.locationInWindow, from: nil)
        isDragging = false

        // Convert from view coordinates (flipped NSView) to screen coordinates
        let viewRect = NSRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        guard viewRect.width > 5, viewRect.height > 5 else {
            startPoint = nil
            currentPoint = nil
            needsDisplay = true
            return
        }

        // Convert to screen coordinates
        // NSView has flipped=false by default, so y=0 is bottom
        // window.frame.origin is the bottom-left of the window (= screen.frame.origin)
        if let windowOrigin = overlayWindow?.frame.origin {
            let screenRect = CGRect(
                x: windowOrigin.x + viewRect.origin.x,
                y: windowOrigin.y + viewRect.origin.y,
                width: viewRect.width,
                height: viewRect.height
            )
            overlayWindow?.reportRect(screenRect)
        }

        startPoint = nil
        currentPoint = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            overlayWindow?.overlayController?.close()
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        // Semi-transparent dark overlay
        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()

        guard let start = startPoint, let current = currentPoint else { return }

        let selRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )

        // Clear the selection area
        NSColor.clear.setFill()
        NSBezierPath(rect: selRect).fill()

        // White border
        NSColor.white.setStroke()
        let path = NSBezierPath(rect: selRect)
        path.lineWidth = 2
        path.stroke()

        // Dimensions label
        let w = Int(selRect.width)
        let h = Int(selRect.height)
        let label = "\(w) × \(h)"
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .shadow: {
                let s = NSShadow()
                s.shadowColor = NSColor.black
                s.shadowBlurRadius = 3
                return s
            }()
        ]
        let str = NSAttributedString(string: label, attributes: attrs)
        let labelSize = str.size()
        var labelOrigin = CGPoint(
            x: selRect.midX - labelSize.width / 2,
            y: selRect.maxY + 6
        )
        // Keep on screen
        if labelOrigin.y + labelSize.height > bounds.maxY {
            labelOrigin.y = selRect.minY - labelSize.height - 6
        }
        str.draw(at: labelOrigin)
    }
}
