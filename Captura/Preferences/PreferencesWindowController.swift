import Cocoa

class PreferencesWindowController: NSObject, NSWindowDelegate {
    static let shared = PreferencesWindowController()
    private var window: NSWindow?

    func show() {
        if let window = window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Captura — Preferences"
        win.center()
        win.delegate = self
        win.level = .floating

        let tabView = NSTabView()
        tabView.autoresizingMask = [.width, .height]

        let generalTab = makeGeneralTab()
        let generalItem = NSTabViewItem(identifier: "general")
        generalItem.label = "General"
        generalItem.view = generalTab
        tabView.addTabViewItem(generalItem)

        let appearanceTab = makeAppearanceTab()
        let appearanceItem = NSTabViewItem(identifier: "appearance")
        appearanceItem.label = "Appearance"
        appearanceItem.view = appearanceTab
        tabView.addTabViewItem(appearanceItem)

        let shortcutsTab = makeShortcutsTab()
        let shortcutsItem = NSTabViewItem(identifier: "shortcuts")
        shortcutsItem.label = "Shortcuts"
        shortcutsItem.view = shortcutsTab
        tabView.addTabViewItem(shortcutsItem)

        let exportTab = makeExportTab()
        let exportItem = NSTabViewItem(identifier: "export")
        exportItem.label = "Export"
        exportItem.view = exportTab
        tabView.addTabViewItem(exportItem)

        win.contentView = tabView
        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeGeneralTab() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        var yPos: CGFloat = 360

        let launchLabel = NSTextField(labelWithString: "Launch at Login")
        launchLabel.frame = NSRect(x: 20, y: yPos, width: 150, height: 20)
        view.addSubview(launchLabel)

        let launchCheckbox = NSButton(frame: NSRect(x: 180, y: yPos, width: 20, height: 20))
        launchCheckbox.setButtonType(.switch)
        launchCheckbox.state = PreferencesManager.launchAtLogin ? .on : .off
        launchCheckbox.target = self
        launchCheckbox.action = #selector(toggleLaunchAtLogin(_:))
        view.addSubview(launchCheckbox)
        yPos -= 40

        let thumbnailLabel = NSTextField(labelWithString: "Show Floating Thumbnail")
        thumbnailLabel.frame = NSRect(x: 20, y: yPos, width: 200, height: 20)
        view.addSubview(thumbnailLabel)

        let thumbnailCheckbox = NSButton(frame: NSRect(x: 220, y: yPos, width: 20, height: 20))
        thumbnailCheckbox.setButtonType(.switch)
        thumbnailCheckbox.state = PreferencesManager.showFloatingThumbnail ? .on : .off
        thumbnailCheckbox.target = self
        thumbnailCheckbox.action = #selector(toggleFloatingThumbnail(_:))
        view.addSubview(thumbnailCheckbox)
        yPos -= 40

        let wallpaperLabel = NSTextField(labelWithString: "Include Desktop Wallpaper")
        wallpaperLabel.frame = NSRect(x: 20, y: yPos, width: 200, height: 20)
        view.addSubview(wallpaperLabel)

        let wallpaperCheckbox = NSButton(frame: NSRect(x: 220, y: yPos, width: 20, height: 20))
        wallpaperCheckbox.setButtonType(.switch)
        wallpaperCheckbox.state = PreferencesManager.includeWallpaper ? .on : .off
        wallpaperCheckbox.target = self
        wallpaperCheckbox.action = #selector(toggleIncludeWallpaper(_:))
        view.addSubview(wallpaperCheckbox)

        return view
    }

    private func makeAppearanceTab() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        let yPos: CGFloat = 360

        let themeLabel = NSTextField(labelWithString: "Theme:")
        themeLabel.frame = NSRect(x: 20, y: yPos, width: 100, height: 20)
        view.addSubview(themeLabel)

        let themeSegment = NSSegmentedControl(
            frame: NSRect(x: 130, y: yPos - 4, width: 200, height: 28)
        )
        themeSegment.segmentCount = 3
        themeSegment.setLabel("Auto", forSegment: 0)
        themeSegment.setLabel("Light", forSegment: 1)
        themeSegment.setLabel("Dark", forSegment: 2)
        themeSegment.selectedSegment = PreferencesManager.appTheme
        themeSegment.target = self
        themeSegment.action = #selector(changeTheme(_:))
        view.addSubview(themeSegment)

        return view
    }

    private func makeShortcutsTab() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        var yPos: CGFloat = 360

        let regionLabel = NSTextField(labelWithString: "Capture Region:")
        regionLabel.frame = NSRect(x: 20, y: yPos, width: 100, height: 20)
        view.addSubview(regionLabel)

        let regionField = NSTextField(frame: NSRect(x: 130, y: yPos, width: 150, height: 24))
        regionField.stringValue = PreferencesManager.regionHotkey
        regionField.placeholderString = "e.g., Cmd+Shift+A"
        regionField.isEditable = true
        view.addSubview(regionField)
        yPos -= 40

        let fullscreenLabel = NSTextField(labelWithString: "Capture Fullscreen:")
        fullscreenLabel.frame = NSRect(x: 20, y: yPos, width: 130, height: 20)
        view.addSubview(fullscreenLabel)

        let fullscreenField = NSTextField(frame: NSRect(x: 160, y: yPos, width: 150, height: 24))
        fullscreenField.stringValue = PreferencesManager.fullscreenHotkey
        fullscreenField.placeholderString = "e.g., Cmd+Shift+F"
        fullscreenField.isEditable = true
        view.addSubview(fullscreenField)

        let saveBtn = NSButton(frame: NSRect(x: 500, y: 20, width: 80, height: 32))
        saveBtn.title = "Save"
        saveBtn.bezelStyle = .rounded
        saveBtn.target = self
        saveBtn.action = #selector(saveShortcuts(_:))
        view.addSubview(saveBtn)

        return view
    }

    private func makeExportTab() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        var yPos: CGFloat = 360

        let formatLabel = NSTextField(labelWithString: "Format:")
        formatLabel.frame = NSRect(x: 20, y: yPos, width: 100, height: 20)
        view.addSubview(formatLabel)

        let formatPopup = NSPopUpButton(frame: NSRect(x: 130, y: yPos - 4, width: 150, height: 28))
        formatPopup.addItems(withTitles: ["PNG", "JPEG", "TIFF", "WebP"])
        formatPopup.selectItem(withTitle: PreferencesManager.imageFormat)
        formatPopup.target = self
        formatPopup.action = #selector(changeFormat(_:))
        view.addSubview(formatPopup)
        yPos -= 40

        let jpegQualityLabel = NSTextField(labelWithString: "JPEG Quality:")
        jpegQualityLabel.frame = NSRect(x: 20, y: yPos, width: 100, height: 20)
        view.addSubview(jpegQualityLabel)

        let jpegQualitySlider = NSSlider(frame: NSRect(x: 130, y: yPos, width: 200, height: 20))
        jpegQualitySlider.minValue = 0.1
        jpegQualitySlider.maxValue = 1.0
        jpegQualitySlider.doubleValue = PreferencesManager.jpegQuality
        jpegQualitySlider.target = self
        jpegQualitySlider.action = #selector(changeJPEGQuality(_:))
        view.addSubview(jpegQualitySlider)
        yPos -= 40

        let folderLabel = NSTextField(labelWithString: "Save Location:")
        folderLabel.frame = NSRect(x: 20, y: yPos, width: 100, height: 20)
        view.addSubview(folderLabel)

        let folderBtn = NSButton(frame: NSRect(x: 130, y: yPos - 4, width: 120, height: 28))
        folderBtn.title = "Choose Folder"
        folderBtn.bezelStyle = .rounded
        folderBtn.target = self
        folderBtn.action = #selector(chooseSaveFolder(_:))
        view.addSubview(folderBtn)
        yPos -= 40

        let clipboardLabel = NSTextField(labelWithString: "Copy to Clipboard")
        clipboardLabel.frame = NSRect(x: 20, y: yPos, width: 200, height: 20)
        view.addSubview(clipboardLabel)

        let clipboardCheckbox = NSButton(frame: NSRect(x: 220, y: yPos, width: 20, height: 20))
        clipboardCheckbox.setButtonType(.switch)
        clipboardCheckbox.state = PreferencesManager.copyToClipboard ? .on : .off
        clipboardCheckbox.target = self
        clipboardCheckbox.action = #selector(toggleCopyToClipboard(_:))
        view.addSubview(clipboardCheckbox)

        return view
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        PreferencesManager.launchAtLogin = sender.state == .on
    }

    @objc private func toggleFloatingThumbnail(_ sender: NSButton) {
        PreferencesManager.showFloatingThumbnail = sender.state == .on
    }

    @objc private func toggleIncludeWallpaper(_ sender: NSButton) {
        PreferencesManager.includeWallpaper = sender.state == .on
    }

    @objc private func changeTheme(_ sender: NSSegmentedControl) {
        PreferencesManager.appTheme = sender.selectedSegment
        applyTheme()
    }

    @objc private func chooseSaveFolder(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: window ?? NSApplication.shared.mainWindow ?? NSWindow()) { response in
            if response == .OK, let url = panel.url {
                PreferencesManager.saveFolderURL = url
            }
        }
    }

    @objc private func changeFormat(_ sender: NSPopUpButton) {
        if let format = sender.selectedItem?.title {
            PreferencesManager.imageFormat = format
        }
    }

    @objc private func changeJPEGQuality(_ sender: NSSlider) {
        PreferencesManager.jpegQuality = sender.doubleValue
    }

    @objc private func toggleCopyToClipboard(_ sender: NSButton) {
        PreferencesManager.copyToClipboard = sender.state == .on
    }

    @objc private func saveShortcuts(_ sender: NSButton) {
        // TODO: Save shortcuts
    }

    private func applyTheme() {
        switch PreferencesManager.appTheme {
        case 1:
            NSApp.appearance = NSAppearance(named: .aqua)
        case 2:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }
}

enum PreferencesManager {
    private static let defaults = UserDefaults.standard

    static var launchAtLogin: Bool {
        get { defaults.bool(forKey: "launchAtLogin") }
        set { defaults.set(newValue, forKey: "launchAtLogin") }
    }

    static var showFloatingThumbnail: Bool {
        get {
            if let value = defaults.object(forKey: "showFloatingThumbnail") as? Bool {
                return value
            }
            return true
        }
        set { defaults.set(newValue, forKey: "showFloatingThumbnail") }
    }

    static var includeWallpaper: Bool {
        get {
            if let value = defaults.object(forKey: "includeWallpaper") as? Bool {
                return value
            }
            return true
        }
        set { defaults.set(newValue, forKey: "includeWallpaper") }
    }

    static var appTheme: Int {
        get { defaults.integer(forKey: "appTheme") }
        set { defaults.set(newValue, forKey: "appTheme") }
    }

    static var regionHotkey: String {
        get { defaults.string(forKey: "regionHotkey") ?? "Cmd+Shift+A" }
        set { defaults.set(newValue, forKey: "regionHotkey") }
    }

    static var fullscreenHotkey: String {
        get { defaults.string(forKey: "fullscreenHotkey") ?? "Cmd+Shift+F" }
        set { defaults.set(newValue, forKey: "fullscreenHotkey") }
    }

    static var saveFolderURL: URL {
        get {
            if let data = defaults.data(forKey: "saveFolderURL"),
               let url = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSURL.self, from: data) as? URL {
                return url
            }
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Pictures")
                .appendingPathComponent("Captura")
        }
        set {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true) {
                defaults.set(data, forKey: "saveFolderURL")
            }
        }
    }

    static var imageFormat: String {
        get { defaults.string(forKey: "imageFormat") ?? "PNG" }
        set { defaults.set(newValue, forKey: "imageFormat") }
    }

    static var jpegQuality: Double {
        get { defaults.double(forKey: "jpegQuality") == 0 ? 0.8 : defaults.double(forKey: "jpegQuality") }
        set { defaults.set(newValue, forKey: "jpegQuality") }
    }

    static var copyToClipboard: Bool {
        get {
            if let value = defaults.object(forKey: "copyToClipboard") as? Bool {
                return value
            }
            return true
        }
        set { defaults.set(newValue, forKey: "copyToClipboard") }
    }
}
