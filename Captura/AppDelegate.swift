import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        hotkeyManager = HotkeyManager()
        hotkeyManager?.onCaptureRegion = { [weak self] in
            self?.statusBarController?.captureRegion()
        }
        hotkeyManager?.onCaptureFullscreen = { [weak self] in
            self?.statusBarController?.captureFullscreen()
        }
        hotkeyManager?.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregister()
    }
}
