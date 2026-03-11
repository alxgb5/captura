import Cocoa

class AnnotationEditorWindowController: NSObject, NSWindowDelegate {
    var onPin: ((NSImage) -> Void)?
    var onClose: (() -> Void)?

    private var window: NSWindow?
    private var canvasView: AnnotationCanvasView?
    private let sourceImage: NSImage

    private let topToolbarH: CGFloat = 58
    private let bottomToolbarH: CGFloat = 48

    init(image: NSImage) {
        self.sourceImage = image
    }

    func show() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let maxW = screen.visibleFrame.width * 0.9
        let maxH = screen.visibleFrame.height * 0.85

        let imgSize = sourceImage.size
        let scale = min(maxW / imgSize.width, (maxH - topToolbarH - bottomToolbarH) / imgSize.height, 1.0)
        let canvasSize = CGSize(width: max(imgSize.width * scale, 600), height: imgSize.height * scale)
        let windowSize = CGSize(width: canvasSize.width, height: canvasSize.height + topToolbarH + bottomToolbarH)

        let win = NSWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Captura — Annotate"
        win.center()
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.level = .floating

        let contentView = NSView(frame: NSRect(origin: .zero, size: windowSize))
        contentView.wantsLayer = true
        win.contentView = contentView

        // Top toolbar
        let topBar = makeTopToolbar(width: windowSize.width)
        topBar.frame = NSRect(x: 0, y: windowSize.height - topToolbarH, width: windowSize.width, height: topToolbarH)
        topBar.autoresizingMask = [.width, .minYMargin]
        contentView.addSubview(topBar)

        // Separator
        let topSep = NSBox(frame: NSRect(x: 0, y: windowSize.height - topToolbarH - 1, width: windowSize.width, height: 1))
        topSep.boxType = .separator
        topSep.autoresizingMask = [.width, .minYMargin]
        contentView.addSubview(topSep)

        // Canvas
        let canvasFrame = NSRect(
            x: 0, y: bottomToolbarH,
            width: windowSize.width, height: canvasSize.height
        )
        let canvas = AnnotationCanvasView(frame: canvasFrame)
        canvas.baseImage = sourceImage
        canvas.autoresizingMask = [.width, .height]
        contentView.addSubview(canvas)
        self.canvasView = canvas

        // Bottom separator
        let botSep = NSBox(frame: NSRect(x: 0, y: bottomToolbarH, width: windowSize.width, height: 1))
        botSep.boxType = .separator
        botSep.autoresizingMask = [.width, .maxYMargin]
        contentView.addSubview(botSep)

        // Bottom toolbar
        let bottomBar = makeBottomToolbar(width: windowSize.width)
        bottomBar.frame = NSRect(x: 0, y: 0, width: windowSize.width, height: bottomToolbarH)
        bottomBar.autoresizingMask = [.width, .maxYMargin]
        contentView.addSubview(bottomBar)

        self.window = win
        win.makeKeyAndOrderFront(nil)
        win.makeFirstResponder(canvas)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() { window?.close() }

    func windowWillClose(_ notification: Notification) { onClose?() }

    // MARK: - Top Toolbar

    private var colorWell: NSColorWell?
    private var strokeSegment: NSSegmentedControl?

    private func makeTopToolbar(width: CGFloat) -> NSView {
        let bar = NSView(frame: .zero)
        bar.wantsLayer = true

        // Liquid Glass background
        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: CGSize(width: width, height: topToolbarH)))
        effectView.blendingMode = .behindWindow
        effectView.material = .hudWindow
        effectView.state = .active
        effectView.autoresizingMask = [.width, .height]
        bar.addSubview(effectView, positioned: .below, relativeTo: nil)

        let tools: [(String, String, AnnotationTool)] = [
            ("arrow.up.right", "Arrow", .arrow),
            ("rectangle", "Rect", .rect),
            ("rectangle.fill", "Highlight", .highlight),
            ("text.cursor", "Text", .text),
            ("camera.filters", "Blur", .blur),
            ("scribble", "Pen", .pen)
        ]

        var x: CGFloat = 12
        let btnSize: CGFloat = 32
        let btnSpacing: CGFloat = 4

        // Tool buttons with glass hover effect
        for (icon, tip, tool) in tools {
            let btn = ToolButton(frame: NSRect(x: x, y: (topToolbarH - btnSize) / 2, width: btnSize, height: btnSize))
            if let img = NSImage(systemSymbolName: icon, accessibilityDescription: tip) {
                btn.image = img
            }
            btn.toolTip = tip
            btn.bezelStyle = .regularSquare
            btn.isBordered = false
            btn.wantsLayer = true
            btn.layer?.cornerRadius = 6
            btn.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.1).cgColor
            btn.annotationTool = tool
            btn.target = self
            btn.action = #selector(toolSelected(_:))
            bar.addSubview(btn)
            x += btnSize + btnSpacing
        }

        // Separator
        x += 4
        let sep1 = NSBox(frame: NSRect(x: x, y: 10, width: 1, height: topToolbarH - 20))
        sep1.boxType = .separator
        bar.addSubview(sep1)
        x += 10

        // Color well
        let well = NSColorWell(frame: NSRect(x: x, y: (topToolbarH - 26) / 2, width: 34, height: 26))
        well.color = .systemRed
        well.target = self
        well.action = #selector(colorChanged(_:))
        bar.addSubview(well)
        self.colorWell = well
        x += 42

        // Stroke width segmented control
        let seg = NSSegmentedControl(
            labels: ["Thin", "Med", "Thick"],
            trackingMode: .selectOne,
            target: self,
            action: #selector(strokeChanged(_:))
        )
        seg.selectedSegment = 1
        seg.frame = NSRect(x: x, y: (topToolbarH - 24) / 2, width: 120, height: 24)
        bar.addSubview(seg)
        self.strokeSegment = seg
        x += 128

        // Separator
        let sep2 = NSBox(frame: NSRect(x: x, y: 10, width: 1, height: topToolbarH - 20))
        sep2.boxType = .separator
        bar.addSubview(sep2)
        x += 10

        // Undo button
        let undo = NSButton(frame: NSRect(x: x, y: (topToolbarH - 26) / 2, width: 70, height: 26))
        undo.title = "Undo"
        if let img = NSImage(systemSymbolName: "arrow.uturn.backward", accessibilityDescription: "Undo") {
            undo.image = img
        }
        undo.imagePosition = .imageLeading
        undo.bezelStyle = .rounded
        undo.target = self
        undo.action = #selector(undoAction)
        bar.addSubview(undo)

        return bar
    }

    // MARK: - Bottom Toolbar

    private func makeBottomToolbar(width: CGFloat) -> NSView {
        let bar = NSView(frame: .zero)
        bar.wantsLayer = true

        // Liquid Glass background
        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: CGSize(width: width, height: bottomToolbarH)))
        effectView.blendingMode = .withinWindow
        effectView.material = .hudWindow
        effectView.state = .active
        effectView.autoresizingMask = [.width, .height]
        bar.addSubview(effectView, positioned: .below, relativeTo: nil)

        let buttons: [(String, String, Selector)] = [
            ("doc.on.doc", "Copy", #selector(copyAction)),
            ("square.and.arrow.down", "Save", #selector(saveAction)),
            ("text.viewfinder", "OCR", #selector(ocrAction)),
            ("pin", "Pin", #selector(pinAction)),
            ("trash", "Discard", #selector(discardAction))
        ]

        let btnW: CGFloat = 80
        let spacing: CGFloat = 8
        let totalW = CGFloat(buttons.count) * btnW + CGFloat(buttons.count - 1) * spacing
        var x = (width - totalW) / 2

        for (icon, title, sel) in buttons {
            let btn = NSButton(frame: NSRect(x: x, y: (bottomToolbarH - 28) / 2, width: btnW, height: 28))
            btn.title = title
            btn.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
            btn.imagePosition = .imageLeading
            btn.bezelStyle = .rounded
            btn.target = self
            btn.action = sel
            bar.addSubview(btn)
            x += btnW + spacing
        }

        return bar
    }

    // MARK: - Toolbar Actions

    @objc private func toolSelected(_ sender: ToolButton) {
        canvasView?.currentTool = sender.annotationTool
    }

    @objc private func colorChanged(_ sender: NSColorWell) {
        canvasView?.currentColor = sender.color
    }

    @objc private func strokeChanged(_ sender: NSSegmentedControl) {
        let widths: [StrokeWidth] = [.thin, .medium, .thick]
        canvasView?.currentStrokeWidth = widths[sender.selectedSegment]
    }

    @objc private func undoAction() {
        canvasView?.undoLast()
    }

    // MARK: - Bottom Actions

    @objc private func copyAction() {
        guard let canvas = canvasView else { return }
        let rendered = canvas.renderToImage()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([rendered])
    }

    @objc private func saveAction() {
        guard let win = window, let canvas = canvasView else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "screenshot-\(Int(Date().timeIntervalSince1970)).png"
        panel.beginSheetModal(for: win) { [weak canvas] response in
            guard response == .OK, let url = panel.url, let canvas = canvas else { return }
            let image = canvas.renderToImage()
            if let tiff = image.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: url)
                NotificationManager.showSaveNotification(filename: url.lastPathComponent)
            }
        }
    }

    @objc private func pinAction() {
        guard let canvas = canvasView else { return }
        onPin?(canvas.renderToImage())
        window?.close()
    }

    @objc private func discardAction() {
        window?.close()
    }

    @objc private func ocrAction() {
        guard let canvas = canvasView else { return }
        let image = canvas.renderToImage()
        OCRManager.recognizeText(in: image) { [weak self] texts in
            let fullText = texts.joined(separator: "\n")
            let alert = NSAlert()
            alert.messageText = "Recognized Text"
            alert.informativeText = fullText.isEmpty ? "No text found" : fullText
            alert.addButton(withTitle: "Copy")
            alert.addButton(withTitle: "Close")
            if let window = self?.window {
                alert.beginSheetModal(for: window) { response in
                    if response == .alertFirstButtonReturn {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(fullText, forType: .string)
                    }
                }
            }
        }
    }
}

// MARK: - ToolButton

private class ToolButton: NSButton {
    var annotationTool: AnnotationTool = .arrow
}
