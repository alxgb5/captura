# Captura 📸

A lightweight, native macOS screenshot and screen capture app — a free, open-source alternative to CleanShot X.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

---

## Features

| Feature | Status |
|---|---|
| 📐 Region capture (crosshair) | ✅ |
| 🖥 Fullscreen capture | ✅ |
| 📌 Pin screenshot to screen | ✅ |
| ⌨️ Global hotkeys | ✅ |
| 📋 Copy to clipboard | ✅ |
| 💾 Save to file | ✅ |
| 🎥 Screen recording | 🔜 |
| ✏️ Annotations | 🔜 |
| 🔍 OCR (text recognition) | 🔜 |

---

## Installation

### Requirements
- macOS 13.0 (Ventura) or later
- Xcode 15+ (to build from source)

### Build from source

```bash
git clone https://github.com/alxgb5/captura.git
cd captura
xcodebuild -project Captura.xcodeproj -scheme Captura build
open build/Release/Captura.app
```

> **Note:** If you only have Command Line Tools (no full Xcode), use the included `project.yml` with [XcodeGen](https://github.com/yonas/XcodeGen) to regenerate the project, or compile directly with `swiftc`.

---

## Usage

Once launched, Captura lives in your **menu bar**. No Dock icon — it stays out of your way.

### Hotkeys

| Shortcut | Action |
|---|---|
| `⌘ Shift 2` | Capture region |
| `⌘ Shift 3` | Capture fullscreen |

### Capture workflow

1. Trigger a capture via hotkey or menu bar
2. Draw your selection (region mode)
3. The capture window appears with options:
   - **Copy** → copies to clipboard
   - **Save** → saves as PNG to Desktop
   - **Pin** → floats the screenshot above all windows

---

## Architecture

```
Captura/
├── AppDelegate.swift         # App entry point, NSApplicationDelegate
├── StatusBarController.swift # Menu bar icon & dropdown menu
├── CaptureManager.swift      # Screenshot logic (CGWindowList / ScreenCaptureKit)
├── OverlayWindow.swift       # Crosshair region selector overlay
├── ResultWindow.swift        # Post-capture window (Copy / Save / Pin)
├── PinnedWindow.swift        # Floating pinned screenshot window
├── HotkeyManager.swift       # Global keyboard shortcuts
└── Info.plist                # App metadata & privacy descriptions
```

---

## Permissions

Captura requires **Screen Recording** permission on first launch.
Go to **System Settings → Privacy & Security → Screen Recording** and enable Captura.

---

## Roadmap

- [ ] Screen recording (MP4 export)
- [ ] Annotation tools (arrows, text, blur, highlight)
- [ ] Scrolling capture
- [ ] OCR (Vision framework)
- [ ] Capture history
- [ ] Custom save location & naming

---

## Contributing

PRs welcome. Open an issue first for major changes.

---

## License

MIT — do whatever you want with it.
