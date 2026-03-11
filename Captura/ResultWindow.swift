import Cocoa

class ResultWindowController: NSObject, NSWindowDelegate {
    var onPin: (() -> Void)?
    var onClose: (() -> Void)?
    private var window: NSWindow?
    private let image: NSImage

    init(image: NSImage) {
        self.image = image
    }

    func show() {
        let imgSize = image.size
        let maxW: CGFloat = 800
        let maxH: CGFloat = 600
        let scale = min(maxW / imgSize.width, maxH / imgSize.height, 1.0)
        let displaySize = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
        let toolbarH: CGFloat = 50
        let windowSize = CGSize(width: max(displaySize.width, 300), height: displaySize.height + toolbarH)

        let win = NSWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Captura"
        win.center()
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.level = .floating

        let contentView = ResultContentView(
            image: image,
            displaySize: displaySize,
            windowWidth: windowSize.width,
            toolbarHeight: toolbarH
        )
        contentView.onCopy = { [weak self] in self?.copyImage() }
        contentView.onSave = { [weak self] in self?.saveImage() }
        contentView.onPin = { [weak self] in self?.onPin?() }
        win.contentView = contentView

        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
    }

    func bringToFront() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    private func copyImage() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }

    private func saveImage() {
        guard let window = window else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "screenshot-\(Int(Date().timeIntervalSince1970)).png"
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url, let self = self else { return }
            if let tiff = self.image.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: url)
                NotificationManager.showSaveNotification(filename: url.lastPathComponent)
            }
        }
    }
}

class ResultContentView: NSView {
    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?
    var onPin: (() -> Void)?

    private let image: NSImage
    private let displaySize: CGSize
    private let toolbarHeight: CGFloat

    init(image: NSImage, displaySize: CGSize, windowWidth: CGFloat, toolbarHeight: CGFloat) {
        self.image = image
        self.displaySize = displaySize
        self.toolbarHeight = toolbarHeight
        let frame = NSRect(
            x: 0, y: 0,
            width: windowWidth,
            height: displaySize.height + toolbarHeight
        )
        super.init(frame: frame)
        setupSubviews(windowWidth: windowWidth)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupSubviews(windowWidth: CGFloat) {
        // Image view
        let imageView = NSImageView(frame: NSRect(
            x: (windowWidth - displaySize.width) / 2,
            y: toolbarHeight,
            width: displaySize.width,
            height: displaySize.height
        ))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(imageView)

        // Toolbar
        let toolbar = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: toolbarHeight))
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        addSubview(toolbar)

        // Separator line
        let sep = NSBox(frame: NSRect(x: 0, y: toolbarHeight - 1, width: windowWidth, height: 1))
        sep.boxType = .separator
        addSubview(sep)

        let buttons: [(String, String, () -> Void)] = [
            ("doc.on.doc", "Copy", { [weak self] in self?.onCopy?() }),
            ("square.and.arrow.down", "Save", { [weak self] in self?.onSave?() }),
            ("pin", "Pin", { [weak self] in self?.onPin?() })
        ]

        let btnW: CGFloat = 80
        let spacing: CGFloat = 8
        let totalW = CGFloat(buttons.count) * btnW + CGFloat(buttons.count - 1) * spacing
        var x = (windowWidth - totalW) / 2

        for (icon, title, action) in buttons {
            let btn = makeButton(icon: icon, title: title, action: action)
            btn.frame = NSRect(x: x, y: (toolbarHeight - 30) / 2, width: btnW, height: 30)
            toolbar.addSubview(btn)
            x += btnW + spacing
        }
    }

    private func makeButton(icon: String, title: String, action: @escaping () -> Void) -> NSButton {
        let btn = ActionButton(frame: .zero)
        btn.title = title
        btn.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
        btn.imagePosition = .imageLeading
        btn.bezelStyle = .rounded
        btn.actionHandler = action
        btn.target = btn
        btn.action = #selector(ActionButton.performAction)
        return btn
    }
}

class ActionButton: NSButton {
    var actionHandler: (() -> Void)?
    @objc func performAction() { actionHandler?() }
}
