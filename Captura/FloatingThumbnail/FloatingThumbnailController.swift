import Cocoa

class FloatingThumbnailController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var image: NSImage
    var onThumbnailClick: (() -> Void)?

    init(image: NSImage) {
        self.image = image
    }

    func show(duration: TimeInterval = 3.0) {
        let thumbnailSize: CGFloat = 120
        let padding: CGFloat = 16

        guard let screen = NSScreen.main else { return }

        let frame = NSRect(
            x: screen.visibleFrame.maxX - thumbnailSize - padding,
            y: screen.visibleFrame.minY + padding,
            width: thumbnailSize,
            height: thumbnailSize
        )

        let win = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        win.isOpaque = false
        win.backgroundColor = NSColor.clear
        win.level = .floating
        win.hasShadow = true
        win.delegate = self

        let contentView = ThumbnailClickableView(frame: NSRect(x: 0, y: 0, width: thumbnailSize, height: thumbnailSize))
        contentView.image = image
        contentView.onClick = { [weak self] in
            self?.onThumbnailClick?()
            win.close()
        }

        win.contentView = contentView
        self.window = win
        win.makeKeyAndOrderFront(nil)

        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.window?.close()
        }
    }

    func windowWillClose(_ notification: Notification) { }
}

class ThumbnailClickableView: NSView {
    var image: NSImage?
    var onClick: (() -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw border
        NSColor.gray.setStroke()
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 8, yRadius: 8)
        border.lineWidth = 2
        border.stroke()

        // Draw image
        if let img = image {
            img.draw(in: bounds.insetBy(dx: 4, dy: 4))
        }
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}
