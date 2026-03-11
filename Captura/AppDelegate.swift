import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        applyTheme()
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

    private func applyTheme() {
        let theme = UserDefaults.standard.integer(forKey: "appTheme")
        switch theme {
        case 1:
            NSApp.appearance = NSAppearance(named: .aqua)
        case 2:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.unregister()
    }
}
