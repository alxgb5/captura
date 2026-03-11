import Cocoa

enum AppIconGenerator {
    static func generateAndSaveIcon() {
        let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
        var imageReps: [NSBitmapImageRep] = []

        for size in sizes {
            if let rep = generateIconRep(size: size) {
                imageReps.append(rep)
            }
        }

        let icnsData = createICNSData(from: imageReps)
        let resourcesPath = Bundle.main.bundlePath + "/Contents/Resources"
        try? FileManager.default.createDirectory(atPath: resourcesPath, withIntermediateDirectories: true)

        let iconPath = URL(fileURLWithPath: resourcesPath + "/AppIcon.icns")
        try? icnsData.write(to: iconPath, options: .atomic)
    }

    private static func generateIconRep(size: Int) -> NSBitmapImageRep? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context

        // Dark background
        NSColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: size, height: size).fill()

        // Draw camera symbol
        if let cameraImage = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Camera") {
            let symbolSize = CGFloat(size) * 0.6
            let cameraRect = NSRect(
                x: (CGFloat(size) - symbolSize) / 2,
                y: (CGFloat(size) - symbolSize) / 2,
                width: symbolSize,
                height: symbolSize
            )
            NSColor.white.setFill()
            cameraImage.draw(in: cameraRect)
        }

        NSGraphicsContext.current = nil
        return rep
    }

    private static func createICNSData(from reps: [NSBitmapImageRep]) -> Data {
        // ICNS file structure
        var data = Data()

        // ICNS header
        data.append("icns".data(using: .ascii) ?? Data())
        let fileSize = UInt32(data.count + 4)
        data.append(withUnsafeBytes(of: CFSwapInt32HostToBig(fileSize)) { Data($0) })

        for rep in reps {
            let pixelWidth = rep.pixelsWide
            let typeCode = iconTypeForSize(pixelWidth)

            let iconData = rep.tiffRepresentation ?? Data()

            if !iconData.isEmpty {
                data.append(typeCode.data(using: .ascii) ?? Data())
                let iconSize = UInt32(iconData.count + 8)
                data.append(withUnsafeBytes(of: CFSwapInt32HostToBig(iconSize)) { Data($0) })
                data.append(iconData)
            }
        }

        // Update file size
        let finalSize = UInt32(data.count)
        var finalSizeData = Data()
        finalSizeData.append(withUnsafeBytes(of: CFSwapInt32HostToBig(finalSize)) { Data($0) })
        if data.count >= 4 {
            data.replaceSubrange(4..<8, with: finalSizeData)
        }

        return data
    }

    private static func iconTypeForSize(_ size: Int) -> String {
        switch size {
        case 16: return "ic04"
        case 32: return "ic05"
        case 64: return "ic06"
        case 128: return "ic07"
        case 256: return "ic08"
        case 512: return "ic09"
        case 1024: return "ic10"
        default: return "ic08"
        }
    }
}
