import Cocoa
import CoreGraphics

// MARK: - Window info model

struct WindowInfo {
    let windowID: CGWindowID
    let bounds: CGRect   // in NSScreen coordinates (y=0 at bottom of primary screen)
    let ownerName: String
    let title: String
}

// MARK: - Controller

class WindowCaptureController: NSObject {
    var onCapture: ((NSImage?) -> Void)?
    private var overlayWindows: [NSWindow] = []

    func show() {
        let windows = enumerateWindows()
        for screen in NSScreen.screens {
            let overlay = WindowCaptureWindow(screen: screen, windowInfos: windows)
            overlay.captureController = self
            overlay.makeKeyAndOrderFront(nil)
            overlayWindows.append(overlay)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
    }

    func didSelectWindow(_ info: WindowInfo) {
        close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            let image = CaptureManager.captureWindow(info)
            self?.onCapture?(image)
        }
    }

    func cancel() {
        close()
        onCapture?(nil)
    }

    // MARK: - Enumerate windows

    private func enumerateWindows() -> [WindowInfo] {
        guard let list = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return [] }

        let primaryH = NSScreen.screens.first?.frame.height ?? 0

        return list.compactMap { dict in
            guard
                let windowID = dict[kCGWindowNumber as String] as? CGWindowID,
                let layer = dict[kCGWindowLayer as String] as? Int, layer == 0,
                let boundsDict = dict[kCGWindowBounds as String] as? [String: Any],
                let cgX = boundsDict["X"] as? CGFloat,
                let cgY = boundsDict["Y"] as? CGFloat,
                let cgW = boundsDict["Width"] as? CGFloat,
                let cgH = boundsDict["Height"] as? CGFloat,
                cgW > 50, cgH > 50
            else { return nil }

            // CG coords: y=0 at top of primary screen
            // NS coords: y=0 at bottom of primary screen
            let nsY = primaryH - cgY - cgH
            let bounds = CGRect(x: cgX, y: nsY, width: cgW, height: cgH)
            let owner = dict[kCGWindowOwnerName as String] as? String ?? ""
            let title = dict[kCGWindowName as String] as? String ?? owner

            return WindowInfo(windowID: windowID, bounds: bounds, ownerName: owner, title: title.isEmpty ? owner : title)
        }
    }
}

// MARK: - Overlay Window

class WindowCaptureWindow: NSWindow {
    weak var captureController: WindowCaptureController?

    init(screen: NSScreen, windowInfos: [WindowInfo]) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = WindowCaptureView(frame: screen.frame, windowInfos: windowInfos, screen: screen)
        view.captureWindow = self
        contentView = view
    }

    override var canBecomeKey: Bool { true }

    func reportSelection(_ info: WindowInfo) {
        captureController?.didSelectWindow(info)
    }

    func reportCancel() {
        captureController?.cancel()
    }
}

// MARK: - Overlay View

class WindowCaptureView: NSView {
    weak var captureWindow: WindowCaptureWindow?
    private let windowInfos: [WindowInfo]
    private let screen: NSScreen
    private var hoveredInfo: WindowInfo?

    init(frame: NSRect, windowInfos: [WindowInfo], screen: NSScreen) {
        self.windowInfos = windowInfos
        self.screen = screen
        super.init(frame: frame)

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }
    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }

    override func mouseMoved(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        // pt is in NSView coords (y=0 at bottom since isFlipped=false)
        // Convert to NS screen coords
        let screenPt = CGPoint(
            x: screen.frame.origin.x + pt.x,
            y: screen.frame.origin.y + pt.y
        )
        hoveredInfo = windowInfos.first { $0.bounds.contains(screenPt) }
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        if let info = hoveredInfo {
            captureWindow?.reportSelection(info)
        } else {
            captureWindow?.reportCancel()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { captureWindow?.reportCancel() }
    }

    override func draw(_ dirtyRect: NSRect) {
        // Dark translucent overlay
        NSColor.black.withAlphaComponent(0.4).setFill()
        bounds.fill()

        guard let info = hoveredInfo else { return }

        // Convert window bounds (NS screen coords) to view coords
        let viewRect = CGRect(
            x: info.bounds.origin.x - screen.frame.origin.x,
            y: info.bounds.origin.y - screen.frame.origin.y,
            width: info.bounds.width,
            height: info.bounds.height
        )

        // Clear the highlight area
        NSColor.clear.setFill()
        NSBezierPath(rect: viewRect).fill()

        // Blue highlight border
        NSColor.systemBlue.withAlphaComponent(0.9).setStroke()
        let path = NSBezierPath(rect: viewRect.insetBy(dx: 1, dy: 1))
        path.lineWidth = 2
        path.stroke()

        // Label with window title
        let label = info.title
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .shadow: {
                let s = NSShadow()
                s.shadowColor = .black
                s.shadowBlurRadius = 3
                return s
            }()
        ]
        let str = NSAttributedString(string: label, attributes: attrs)
        let sz = str.size()
        let labelPadding: CGFloat = 6
        let bgRect = CGRect(
            x: viewRect.midX - sz.width / 2 - labelPadding,
            y: viewRect.maxY + 6,
            width: sz.width + labelPadding * 2,
            height: sz.height + 4
        )
        NSColor.black.withAlphaComponent(0.65).setFill()
        NSBezierPath(roundedRect: bgRect, xRadius: 4, yRadius: 4).fill()
        str.draw(at: CGPoint(x: bgRect.origin.x + labelPadding, y: bgRect.origin.y + 2))
    }
}
