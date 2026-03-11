import Cocoa

enum ImageExporter {
    enum ExportFormat {
        case png
        case jpeg(quality: Double)
        case tiff
        case webp(quality: Double)

        var fileExtension: String {
            switch self {
            case .png: return "png"
            case .jpeg: return "jpg"
            case .tiff: return "tiff"
            case .webp: return "webp"
            }
        }
    }

    static func export(_ image: NSImage, as format: ExportFormat) -> Data? {
        guard let tiffData = image.tiffRepresentation else { return nil }
        guard let bitmapImage = NSBitmapImageRep(data: tiffData) else { return nil }

        switch format {
        case .png:
            return bitmapImage.representation(using: .png, properties: [:])

        case .jpeg(let quality):
            let clampedQuality = max(0.0, min(1.0, quality))
            return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: clampedQuality])

        case .tiff:
            return bitmapImage.representation(using: .tiff, properties: [:])

        case .webp(let quality):
            // WebP not natively supported by NSBitmapImageRep — fallback to PNG
            _ = quality
            return bitmapImage.representation(using: .png, properties: [:])
        }
    }

    static func exportToFile(_ image: NSImage, at url: URL, as format: ExportFormat) -> Bool {
        guard let data = export(image, as: format) else { return false }
        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }
}
