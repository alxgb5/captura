import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppIconGenerator.generateAndSaveIcon()
        NotificationManager.requestPermissions()
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
