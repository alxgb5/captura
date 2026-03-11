# Captura

![macOS](https://img.shields.io/badge/macOS-26+-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)
![Tests](https://img.shields.io/badge/tests-passing-brightgreen?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)
![Release](https://img.shields.io/github/v/release/alxgb5/captura?style=flat-square)

> Native macOS screenshot app with annotations, OCR, screen recording and Liquid Glass UI.

![Captura demo](docs/assets/preview.png)

---

## Features

- **Region / Fullscreen / Window capture** — hotkey-driven, no permissions required
- **Scrolling capture** — auto-scroll + vertical stitch
- **Screen recording** → MP4 via ScreenCaptureKit
- **Annotation editor** — arrows, rectangles, text, highlight, blur, pen
- **OCR** — extract text from any screenshot via Vision framework
- **Floating thumbnail** — draggable post-capture preview with quick actions
- **Pin to screen** — float any screenshot over other windows
- **Capture history** — last 20 captures
- **Preferences** — theme (light/dark/auto), export format, wallpaper toggle, custom hotkeys
- **Liquid Glass UI** — native macOS 26 design language

---

## Install

Download the latest [Captura.dmg](https://github.com/alxgb5/captura/releases/latest), open it and drag to Applications.

> No Gatekeeper prompt — app is ad-hoc signed.

---

## Build from source

**Requirements:** macOS 26+, Xcode Command Line Tools (`xcode-select --install`)

```bash
git clone https://github.com/alxgb5/captura
cd captura
./build.sh
open build/Captura.app
```

---

## Usage

Captura lives in the menu bar (📸). Click the icon or use hotkeys:

| Action | Default shortcut |
|---|---|
| Capture region | `⌘⇧A` |
| Capture fullscreen | `⌘⇧F` |
| Capture window | via menu |
| Scrolling capture | via menu |
| Start/stop recording | via menu |

Shortcuts are rebindable in **Preferences → Shortcuts**.

---

## Testing

```bash
swift test
```

---

## License

MIT
