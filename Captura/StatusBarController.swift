import Cocoa

class StatusBarController {
    private var statusItem: NSStatusItem
    private var overlayWindowController: OverlayWindowController?
    private var resultWindowControllers: [ResultWindowController] = []
    private var pinnedWindowControllers: [PinnedWindowController] = []
    private var scrollingCaptureManager: ScrollingCaptureManager?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage.renderSymbol("camera.fill", size: 18)
        }
        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Capture Region", action: #selector(captureRegionAction), keyEquivalent: "")
            .target = self
        menu.addItem(withTitle: "Capture Fullscreen", action: #selector(captureFullscreenAction), keyEquivalent: "")
            .target = self
        menu.addItem(withTitle: "Scrolling Capture", action: #selector(scrollingCaptureAction), keyEquivalent: "")
            .target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Preferences", action: #selector(preferencesAction), keyEquivalent: ",")
            .target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc private func captureRegionAction() { captureRegion() }
    @objc private func captureFullscreenAction() { captureFullscreen() }
    @objc private func scrollingCaptureAction() { scrollingCapture() }
    @objc private func preferencesAction() { showPreferences() }

    func captureRegion() {
        overlayWindowController?.close()
        overlayWindowController = OverlayWindowController()
        overlayWindowController?.onCapture = { [weak self] rect in
            self?.overlayWindowController?.close()
            self?.overlayWindowController = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if let image = CaptureManager.captureRegion(rect) {
                    self?.showResult(image: image)
                }
            }
        }
        overlayWindowController?.show()
    }

    func captureFullscreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let image = CaptureManager.captureFullscreen() {
                self.showResult(image: image)
            }
        }
    }

    private func showResult(image: NSImage) {
        let controller = ResultWindowController(image: image)
        resultWindowControllers.append(controller)
        controller.onPin = { [weak self, weak controller] in
            guard let self = self, let ctrl = controller else { return }
            let pinned = PinnedWindowController(image: image)
            self.pinnedWindowControllers.append(pinned)
            pinned.show()
            ctrl.close()
            self.resultWindowControllers.removeAll { $0 === ctrl }
        }
        controller.onClose = { [weak self, weak controller] in
            guard let ctrl = controller else { return }
            self?.resultWindowControllers.removeAll { $0 === ctrl }
        }
        controller.show()

        // Show floating thumbnail if enabled
        if PreferencesManager.showFloatingThumbnail {
            let thumbnail = FloatingThumbnailController(image: image)
            thumbnail.onThumbnailClick = { [weak controller] in
                controller?.bringToFront()
            }
            thumbnail.show()
        }
    }

    func scrollingCapture() {
        scrollingCaptureManager = ScrollingCaptureManager()
        scrollingCaptureManager?.onComplete = { [weak self] image in
            self?.showAnnotationEditor(image: image)
        }
        scrollingCaptureManager?.start()
    }

    private func showAnnotationEditor(image: NSImage) {
        let controller = AnnotationEditorWindowController(image: image)
        controller.onClose = { }
        controller.onPin = { _ in }
        controller.show()
    }

    func showPreferences() {
        PreferencesWindowController.shared.show()
    }
}
