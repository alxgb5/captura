```markdown
# Captura - macOS Screenshot and Annotation App

## :bulb: Description
Captura is a macOS application that allows users to take screenshots, annotate them, and record videos. It offers a variety of features to enhance the user experience.

## :mag_right: Features
- **Capture Région:** Capture a specific area of the screen.
- **Capture Plein Écran:** Capture the entire screen.
- **Capture de Fenêtre:** Capture a window.
- **Scroll Capture:** Capture the entire screen including scroll areas.
- **Screen Recording (MP4):** Record video snapshots.
- **Annotation Editor:** Flèches, rectangles, texte, highlight, blur, crayon.
- **OCR (via Vision):** Reconnaissez le texte.
- **Historique:** 20 captures précédentes.
- **Floating Thumbnail:** Affichage de petites images après capture.
- **Preferences:** Thèmes (light, dark, auto), formats de fichier d'exportation (PNG, JPEG, TIFF), fond d'écran, raccourments personnalisés.

## :wrench: Install
```bash
./build.sh
open build/Captura.app
```

## :construction: Build
### Prerequisites
- macOS 10.14 or later
- Xcode 12.5 or later

### Build Steps
1. Navigate to the project directory: `cd Captura`
2. Build the project: `xcodebuild -project Captura.xcodeproj -configuration Release`

## :computer: Usage
- **Capture Région:** Press `⌘⇧A` to capture a region.
- **Capture Plein Écran:** Press `⌘⇧F` to capture the entire screen.
- **Capture de Fenêtre:** Press `⌘⇧T` to capture a window.
- **Scroll Capture:** Press `⌘⇧S` to capture the entire screen including scroll areas.
- **Screen Recording:** Press `⌘⇧R` to start recording, press `⌘⇧R` again to stop.
- **Annotation:** Use the built-in annotation tools for text, rectangles, highlight, blur, and more.
- **OCR:** Use the built-in OCR tool to recognize text.
- **Preferences:** Access settings for theme, export formats, and more.

## :clipboard: Shortcuts
| Action      | Shortcut      |
|-------------|---------------|
| Capture Région| `⌘⇧A`        |
| Capture Plein Écran| `⌘⇧F`      |
| Capture de Fenêtre| `⌘⇧T`      |

## :book: Preferences
- **Thème:** Light, Dark, Auto
- **Format d'exportation:** PNG, JPEG, TIFF
- **Fond d'écran:** Activer / Désactiver
- **Raccourments personnalisés:** Custom hotkeys

## :mag_right: Contributing
Contributions are welcome! Please follow the guidelines for submitting issues and pull requests.

---

### :information_source: License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```

