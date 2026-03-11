import Cocoa

class StatusBarController {
    private var statusItem: NSStatusItem
    private var overlayWindowController: OverlayWindowController?
    private var resultWindowControllers: [ResultWindowController] = []
    private var pinnedWindowControllers: [PinnedWindowController] = []

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Captura")
        }
        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Capture Region", action: #selector(captureRegionAction), keyEquivalent: "")
            .target = self
        menu.addItem(withTitle: "Capture Fullscreen", action: #selector(captureFullscreenAction), keyEquivalent: "")
            .target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc private func captureRegionAction() { captureRegion() }
    @objc private func captureFullscreenAction() { captureFullscreen() }

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
    }
}
