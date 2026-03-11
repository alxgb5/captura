import Cocoa

class FloatingThumbnailController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var image: NSImage
    var onEdit: (() -> Void)?
    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?

    init(image: NSImage) {
        self.image = image
    }

    func show(duration: TimeInterval = 4.0) {
        let thumbnailSize: CGFloat = 140
        let padding: CGFloat = 16

        guard let screen = NSScreen.main else { return }

        // Start position (bottom-right, off-screen)
        let startFrame = NSRect(
            x: screen.visibleFrame.maxX - thumbnailSize - padding,
            y: screen.visibleFrame.minY - thumbnailSize,
            width: thumbnailSize,
            height: thumbnailSize
        )

        // End position (bottom-right, on-screen)
        let endFrame = NSRect(
            x: screen.visibleFrame.maxX - thumbnailSize - padding,
            y: screen.visibleFrame.minY + padding,
            width: thumbnailSize,
            height: thumbnailSize
        )

        let win = NSWindow(
            contentRect: startFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        win.isOpaque = false
        win.backgroundColor = NSColor.clear
        win.level = .floating
        win.hasShadow = true
        win.delegate = self
        win.alphaValue = 0.0

        let contentView = ThumbnailView(frame: NSRect(x: 0, y: 0, width: thumbnailSize, height: thumbnailSize))
        contentView.image = image
        contentView.onEdit = { [weak self] in self?.onEdit?() }
        contentView.onCopy = { [weak self] in self?.onCopy?() }
        contentView.onSave = { [weak self] in self?.onSave?() }
        contentView.onDismiss = { [weak win] in win?.close() }

        win.contentView = contentView
        self.window = win
        win.makeKeyAndOrderFront(nil)

        // Animate in (slide up + fade in)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            win.animator().alphaValue = 1.0
            win.animator().setFrame(endFrame, display: true)
        })

        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.animateOut()
        }
    }

    private func animateOut() {
        guard let win = window else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            win.animator().alphaValue = 0.0
        }, completionHandler: {
            win.close()
        })
    }

    func windowWillClose(_ notification: Notification) { }
}

class ThumbnailView: NSView {
    var image: NSImage?
    var onEdit: (() -> Void)?
    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?
    var onDismiss: (() -> Void)?

    private let cornerRadius: CGFloat = 12
    private let buttonSize: CGFloat = 32
    private let padding: CGFloat = 8

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw blur background
        let blurView = NSVisualEffectView(frame: bounds)
        blurView.blendingMode = .behindWindow
        blurView.material = .contentBackground
        blurView.state = .active
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = cornerRadius

        // Draw rounded corner background
        let bgPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor.controlBackgroundColor.setFill()
        bgPath.fill()

        // Draw shadow and border
        let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor.labelColor.withAlphaComponent(0.2).setStroke()
        borderPath.lineWidth = 1
        borderPath.stroke()

        // Draw image
        let imageSize = bounds.height - (padding * 2 + buttonSize + padding)
        let imageFrame = NSRect(
            x: padding,
            y: buttonSize + padding * 2,
            width: imageSize,
            height: imageSize
        )
        if let img = image {
            img.draw(in: imageFrame, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
    }

    override func layout() {
        super.layout()
        setupButtons()
    }

    private func setupButtons() {
        // Remove existing buttons
        subviews.forEach { $0.removeFromSuperview() }

        let btnW: CGFloat = 28
        let spacing: CGFloat = 4
        let topMargin: CGFloat = 4

        // Dismiss button (X)
        let dismissBtn = NSButton(frame: NSRect(x: bounds.width - btnW - topMargin, y: bounds.height - btnW - topMargin, width: btnW, height: btnW))
        dismissBtn.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")
        dismissBtn.bezelStyle = .circular
        dismissBtn.imagePosition = .imageOnly
        dismissBtn.target = self
        dismissBtn.action = #selector(dismissClicked)
        addSubview(dismissBtn)

        // Bottom buttons
        let totalW = (btnW * 3) + (spacing * 2)
        let startX = (bounds.width - totalW) / 2
        let btnY = topMargin

        // Edit
        let editBtn = NSButton(frame: NSRect(x: startX, y: btnY, width: btnW, height: btnW))
        editBtn.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Edit")
        editBtn.bezelStyle = .circular
        editBtn.imagePosition = .imageOnly
        editBtn.target = self
        editBtn.action = #selector(editClicked)
        addSubview(editBtn)

        // Copy
        let copyBtn = NSButton(frame: NSRect(x: startX + btnW + spacing, y: btnY, width: btnW, height: btnW))
        copyBtn.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy")
        copyBtn.bezelStyle = .circular
        copyBtn.imagePosition = .imageOnly
        copyBtn.target = self
        copyBtn.action = #selector(copyClicked)
        addSubview(copyBtn)

        // Save
        let saveBtn = NSButton(frame: NSRect(x: startX + (btnW + spacing) * 2, y: btnY, width: btnW, height: btnW))
        saveBtn.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "Save")
        saveBtn.bezelStyle = .circular
        saveBtn.imagePosition = .imageOnly
        saveBtn.target = self
        saveBtn.action = #selector(saveClicked)
        addSubview(saveBtn)
    }

    @objc private func editClicked() { onEdit?() }
    @objc private func copyClicked() { onCopy?() }
    @objc private func saveClicked() { onSave?() }
    @objc private func dismissClicked() { onDismiss?() }
}
