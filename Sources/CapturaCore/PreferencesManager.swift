import Cocoa

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

    static func reset(for key: String) {
        defaults.removeObject(forKey: key)
    }

    static func resetAll() {
        let keys: [String] = [
            "launchAtLogin", "showFloatingThumbnail", "includeWallpaper", "appTheme",
            "regionHotkey", "fullscreenHotkey", "saveFolderURL", "imageFormat",
            "jpegQuality", "copyToClipboard"
        ]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
    }
}
