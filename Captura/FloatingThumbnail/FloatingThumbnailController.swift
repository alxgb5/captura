import Cocoa

class FloatingThumbnailController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var image: NSImage
    private var view: ThumbnailView?
    private var dismissTimer: Timer?

    var onEdit: (() -> Void)?
    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?
    var onPin: (() -> Void)?

    init(image: NSImage) {
        self.image = image
    }

    func show(duration: TimeInterval = 5.0) {
        let thumbnailW: CGFloat = 240
        let thumbnailH: CGFloat = 160
        let actionBarH: CGFloat = 44
        let totalH = thumbnailH + actionBarH
        let padding: CGFloat = 20

        guard let screen = NSScreen.main else { return }

        // Start position (bottom-right, off-screen)
        let startFrame = NSRect(
            x: screen.visibleFrame.maxX - thumbnailW - padding,
            y: screen.visibleFrame.minY - totalH,
            width: thumbnailW,
            height: totalH
        )

        // End position (bottom-right, on-screen)
        let endFrame = NSRect(
            x: screen.visibleFrame.maxX - thumbnailW - padding,
            y: screen.visibleFrame.minY + padding,
            width: thumbnailW,
            height: totalH
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

        let contentView = ThumbnailView(frame: NSRect(x: 0, y: 0, width: thumbnailW, height: totalH))
        contentView.image = image
        contentView.onEdit = { [weak self] in self?.resetDismissTimer(); self?.onEdit?() }
        contentView.onCopy = { [weak self] in self?.resetDismissTimer(); self?.onCopy?() }
        contentView.onSave = { [weak self] in self?.resetDismissTimer(); self?.onSave?() }
        contentView.onPin = { [weak self] in self?.onPin?() }
        contentView.onMouseEntered = { [weak self] in self?.resetDismissTimer() }

        win.contentView = contentView
        self.window = win
        self.view = contentView
        win.makeKeyAndOrderFront(nil)

        // Slide-in animation with spring effect
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            win.animator().alphaValue = 1.0
            win.animator().setFrame(endFrame, display: true)
        })

        // Set up auto-dismiss timer
        startDismissTimer(duration: duration)
    }

    private func startDismissTimer(duration: TimeInterval) {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.animateOut()
        }
    }

    private func resetDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.animateOut()
        }
    }

    private func animateOut() {
        guard let win = window else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            win.animator().alphaValue = 0.0
        }, completionHandler: {
            win.close()
        })
    }

    func windowWillClose(_ notification: Notification) {
        dismissTimer?.invalidate()
    }
}

class ThumbnailView: NSView {
    var image: NSImage?
    var onEdit: (() -> Void)?
    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?
    var onPin: (() -> Void)?
    var onMouseEntered: (() -> Void)?

    private let cornerRadius: CGFloat = 16
    private let thumbnailH: CGFloat = 160
    private let actionBarH: CGFloat = 44
    private var actionButtons: [ThumbnailActionButton] = []
    private var hovering = false
    private var dragStart: NSPoint = .zero

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTracking()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTracking() {
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Main background with Liquid Glass effect
        let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 0, dy: 0), xRadius: cornerRadius, yRadius: cornerRadius)

        // Liquid Glass background (using NSVisualEffectView material)
        let effectView = NSVisualEffectView(frame: bounds)
        effectView.blendingMode = .withinWindow
        effectView.material = .hudWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = cornerRadius
        effectView.layer?.masksToBounds = true

        // Draw the visual effect background
        effectView.draw(NSRect(origin: .zero, size: bounds.size))

        // Subtle border for Liquid Glass look
        let borderColor = NSColor.white.withAlphaComponent(0.3)
        borderColor.setStroke()
        bgPath.lineWidth = 0.5
        bgPath.stroke()

        // Thumbnail image in upper area
        let imgH = thumbnailH
        let imgFrame = NSRect(
            x: 0,
            y: actionBarH,
            width: bounds.width,
            height: imgH
        )
        if let img = image {
            img.draw(in: imgFrame, from: .zero, operation: .sourceOver, fraction: 1.0)
        }

        // Action bar separator
        NSColor.white.withAlphaComponent(0.2).setStroke()
        let sepPath = NSBezierPath()
        sepPath.move(to: NSPoint(x: 0, y: actionBarH))
        sepPath.line(to: NSPoint(x: bounds.width, y: actionBarH))
        sepPath.lineWidth = 0.5
        sepPath.stroke()
    }

    override func layout() {
        super.layout()
        setupActionBar()
    }

    private func setupActionBar() {
        // Clear existing action buttons
        actionButtons.forEach { $0.removeFromSuperview() }
        actionButtons.removeAll()

        let btnSize: CGFloat = 36
        let spacing: CGFloat = 8
        let totalW = (btnSize * 4) + (spacing * 3)
        let startX = (bounds.width - totalW) / 2
        let btnY = (actionBarH - btnSize) / 2

        let actions: [(String, String, () -> Void)] = [
            ("pencil.circle.fill", "Edit", { [weak self] in self?.onEdit?() }),
            ("doc.on.doc.fill", "Copy", { [weak self] in self?.onCopy?() }),
            ("square.and.arrow.down.fill", "Save", { [weak self] in self?.onSave?() }),
            ("pin.circle.fill", "Pin", { [weak self] in self?.onPin?() })
        ]

        for (i, (icon, label, action)) in actions.enumerated() {
            let btn = ThumbnailActionButton(
                frame: NSRect(
                    x: startX + CGFloat(i) * (btnSize + spacing),
                    y: btnY,
                    width: btnSize,
                    height: btnSize
                )
            )
            btn.setImage(icon: icon, label: label)
            btn.action = action
            btn.alphaValue = hovering ? 1.0 : 0.0
            addSubview(btn)
            actionButtons.append(btn)
        }

        // Animate in the action buttons if hovering
        if hovering {
            animateActionButtonsIn()
        }
    }

    private func animateActionButtonsIn() {
        for btn in actionButtons {
            btn.alphaValue = 0.0
            btn.layer?.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                btn.animator().alphaValue = 1.0
                btn.layer?.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
            })
        }
    }

    private func animateActionButtonsOut() {
        for btn in actionButtons {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                btn.animator().alphaValue = 0.0
            })
        }
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        dragStart = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window else { return }
        let delta = NSPoint(
            x: event.locationInWindow.x - dragStart.x,
            y: event.locationInWindow.y - dragStart.y
        )
        var frame = window.frame
        frame.origin.x += delta.x
        frame.origin.y += delta.y
        window.setFrameOrigin(frame.origin)
    }

    override func mouseMoved(with event: NSEvent) {
        if !hovering && bounds.contains(convert(event.locationInWindow, from: nil)) {
            hovering = true
            onMouseEntered?()
            animateActionButtonsIn()
        } else if hovering && !bounds.contains(convert(event.locationInWindow, from: nil)) {
            hovering = false
            animateActionButtonsOut()
        }
    }
}

// MARK: - Thumbnail Action Button

private class ThumbnailActionButton: NSView {
    var action: (() -> Void)?
    private var imageView: NSImageView?
    private var hoveringButton = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = frameRect.width / 2
        setupImage()
        setupTracking()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupImage() {
        let imageView = NSImageView(frame: NSRect(x: 6, y: 6, width: bounds.width - 12, height: bounds.height - 12))
        imageView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(imageView)
        self.imageView = imageView
    }

    private func setupTracking() {
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    func setImage(icon: String, label: String) {
        if let img = NSImage(systemSymbolName: icon, accessibilityDescription: label) {
            imageView?.image = img
            imageView?.contentTintColor = .white
        }
    }

    override func mouseDown(with event: NSEvent) {
        action?()
    }

    override func mouseMoved(with event: NSEvent) {
        let isHovering = bounds.contains(convert(event.locationInWindow, from: nil))
        if isHovering != hoveringButton {
            hoveringButton = isHovering
            updateBackground()
        }
    }

    private func updateBackground() {
        if hoveringButton {
            layer?.backgroundColor = NSColor.white.withAlphaComponent(0.2).cgColor
        } else {
            layer?.backgroundColor = NSColor.white.withAlphaComponent(0.1).cgColor
        }
    }
}
