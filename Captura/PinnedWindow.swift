import Cocoa

class PinnedWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let image: NSImage

    init(image: NSImage) {
        self.image = image
    }

    func show() {
        let imgSize = image.size
        let scale = min(600 / imgSize.width, 400 / imgSize.height, 1.0)
        let displaySize = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)

        let win = NSWindow(
            contentRect: NSRect(origin: .zero, size: displaySize),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Pinned"
        win.level = .floating
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.center()
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: displaySize))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        win.contentView = imageView

        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
