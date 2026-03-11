import Cocoa
import CoreImage

enum AnnotationTool {
    case arrow, rect, highlight, text, blur, pen
}

enum StrokeWidth: CGFloat, CaseIterable {
    case thin = 2
    case medium = 4
    case thick = 8
}

// MARK: - Protocol

protocol AnnotationShape: AnyObject {
    func draw(baseImage: NSImage?)
}

// MARK: - Arrow

class ArrowShape: AnnotationShape {
    var start: CGPoint
    var end: CGPoint
    var color: NSColor
    var lineWidth: CGFloat

    init(start: CGPoint, end: CGPoint, color: NSColor, lineWidth: CGFloat) {
        self.start = start
        self.end = end
        self.color = color
        self.lineWidth = lineWidth
    }

    func draw(baseImage: NSImage?) {
        color.setStroke()
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.move(to: start)
        path.line(to: end)

        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLen: CGFloat = max(lineWidth * 4, 14)
        let arrowAngle: CGFloat = .pi / 6
        let p1 = CGPoint(
            x: end.x - arrowLen * cos(angle - arrowAngle),
            y: end.y - arrowLen * sin(angle - arrowAngle)
        )
        let p2 = CGPoint(
            x: end.x - arrowLen * cos(angle + arrowAngle),
            y: end.y - arrowLen * sin(angle + arrowAngle)
        )
        path.move(to: end)
        path.line(to: p1)
        path.move(to: end)
        path.line(to: p2)
        path.stroke()
    }
}

// MARK: - Rectangle

class RectShape: AnnotationShape {
    var rect: CGRect
    var color: NSColor
    var lineWidth: CGFloat

    init(rect: CGRect, color: NSColor, lineWidth: CGFloat) {
        self.rect = rect
        self.color = color
        self.lineWidth = lineWidth
    }

    func draw(baseImage: NSImage?) {
        color.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = lineWidth
        path.stroke()
    }
}

// MARK: - Highlight

class HighlightShape: AnnotationShape {
    var rect: CGRect

    init(rect: CGRect) { self.rect = rect }

    func draw(baseImage: NSImage?) {
        NSColor.yellow.withAlphaComponent(0.4).setFill()
        NSBezierPath(rect: rect).fill()
    }
}

// MARK: - Blur

class BlurShape: AnnotationShape {
    var rect: CGRect

    init(rect: CGRect) { self.rect = rect }

    func draw(baseImage: NSImage?) {
        guard let base = baseImage, rect.width > 2, rect.height > 2 else { return }
        guard let cgBase = base.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let scaleX = CGFloat(cgBase.width) / base.size.width
        let scaleY = CGFloat(cgBase.height) / base.size.height
        let pixelRect = CGRect(
            x: rect.origin.x * scaleX,
            y: rect.origin.y * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )

        guard pixelRect.width > 0, pixelRect.height > 0,
              let cropped = cgBase.cropping(to: pixelRect) else { return }

        let ciImage = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CIPixellate") else { return }
        filter.setValue(ciImage.clampedToExtent(), forKey: kCIInputImageKey)
        filter.setValue(max(pixelRect.width, pixelRect.height) / 12.0, forKey: kCIInputScaleKey)
        guard let output = filter.outputImage else { return }

        let ctx = CIContext()
        guard let blurredCG = ctx.createCGImage(output, from: CGRect(origin: .zero, size: CGSize(width: cropped.width, height: cropped.height))) else { return }
        let blurredImage = NSImage(cgImage: blurredCG, size: rect.size)
        blurredImage.draw(in: rect)
    }
}

// MARK: - Freehand

class FreehandShape: AnnotationShape {
    var points: [CGPoint] = []
    var color: NSColor
    var lineWidth: CGFloat

    init(color: NSColor, lineWidth: CGFloat) {
        self.color = color
        self.lineWidth = lineWidth
    }

    func addPoint(_ point: CGPoint) { points.append(point) }

    func draw(baseImage: NSImage?) {
        guard points.count > 1 else { return }
        color.setStroke()
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: points[0])
        for pt in points.dropFirst() { path.line(to: pt) }
        path.stroke()
    }
}

// MARK: - Text

class TextShape: AnnotationShape {
    var origin: CGPoint
    var text: String
    var color: NSColor
    var fontSize: CGFloat

    init(origin: CGPoint, text: String, color: NSColor, fontSize: CGFloat = 18) {
        self.origin = origin
        self.text = text
        self.color = color
        self.fontSize = fontSize
    }

    func draw(baseImage: NSImage?) {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.6)
        shadow.shadowBlurRadius = 2
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
            .shadow: shadow
        ]
        NSAttributedString(string: text, attributes: attrs).draw(at: origin)
    }
}
