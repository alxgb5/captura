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
| 📜 Scrolling capture | ✅ |
| ✏️ Annotations (arrows, text, highlight, blur, pen) | ✅ |
| 🔍 OCR (text recognition) | ✅ |
| 💾 Capture history | ✅ |
| ⚙️ Preferences & settings | ✅ |
| 🎥 Screen recording | 🔜 |

---

## Installation

### Requirements
- macOS 13.0 (Ventura) or later
- Xcode Command Line Tools (or full Xcode)

### Quick Install (from DMG)

Download the latest `Captura.dmg` from [Releases](https://github.com/alxgb5/captura/releases), mount it, and drag Captura to Applications.

### Build from Source

```bash
git clone https://github.com/alxgb5/captura.git
cd captura
./build.sh
open build/Captura.app/Contents/MacOS/Captura
```

The `build.sh` script:
- Compiles all Swift source files with swiftc
- Links required frameworks (Cocoa, ScreenCaptureKit, AVFoundation, Vision)
- Generates an Info.plist
- Ad-hoc signs the binary (so macOS won't block it)

### Create DMG for Distribution

```bash
./scripts/make_dmg.sh
# Output: dist/Captura.dmg
```

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

- [x] Annotation tools (arrows, rect, text, highlight, blur, pen)
- [x] Scrolling capture
- [x] OCR (Vision framework, French + English)
- [x] Capture history
- [x] Preferences & settings
- [ ] Screen recording (MP4 export)
- [ ] Custom save location & naming
- [ ] Keyboard shortcuts customization

---

## Contributing

PRs welcome. Open an issue first for major changes.

---

## License

MIT — do whatever you want with it.
