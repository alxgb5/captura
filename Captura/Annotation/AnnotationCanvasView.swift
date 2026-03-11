import Cocoa

class AnnotationCanvasView: NSView {
    var baseImage: NSImage?
    var currentTool: AnnotationTool = .arrow
    var currentColor: NSColor = .systemRed
    var currentStrokeWidth: StrokeWidth = .medium

    private(set) var annotations: [AnnotationShape] = []
    private var currentShape: AnnotationShape?
    private var dragStart: CGPoint?
    private var pendingTextField: NSTextField?

    // NSView with isFlipped = true means y=0 is at top-left, matching image coords
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Undo / Clear

    func undoLast() {
        guard !annotations.isEmpty else { return }
        annotations.removeLast()
        needsDisplay = true
    }

    // MARK: - Mouse events

    override func mouseDown(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        commitPendingTextField()

        switch currentTool {
        case .arrow:
            currentShape = ArrowShape(start: pt, end: pt, color: currentColor, lineWidth: currentStrokeWidth.rawValue)
            dragStart = pt
        case .rect:
            currentShape = RectShape(rect: CGRect(origin: pt, size: .zero), color: currentColor, lineWidth: currentStrokeWidth.rawValue)
            dragStart = pt
        case .highlight:
            currentShape = HighlightShape(rect: CGRect(origin: pt, size: .zero))
            dragStart = pt
        case .blur:
            currentShape = BlurShape(rect: CGRect(origin: pt, size: .zero))
            dragStart = pt
        case .pen:
            let shape = FreehandShape(color: currentColor, lineWidth: currentStrokeWidth.rawValue)
            shape.addPoint(pt)
            currentShape = shape
            dragStart = pt
        case .text:
            showTextField(at: pt)
            return
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        guard let start = dragStart else { return }

        switch currentTool {
        case .arrow:
            (currentShape as? ArrowShape)?.end = pt
        case .rect:
            (currentShape as? RectShape)?.rect = makeRect(start, pt)
        case .highlight:
            (currentShape as? HighlightShape)?.rect = makeRect(start, pt)
        case .blur:
            (currentShape as? BlurShape)?.rect = makeRect(start, pt)
        case .pen:
            (currentShape as? FreehandShape)?.addPoint(pt)
        case .text:
            break
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let shape = currentShape else { return }
        annotations.append(shape)
        currentShape = nil
        dragStart = nil
        needsDisplay = true
    }

    // MARK: - Text field

    private func showTextField(at point: CGPoint) {
        let tf = NSTextField(frame: NSRect(x: point.x, y: point.y - 26, width: 200, height: 30))
        tf.isEditable = true
        tf.isBordered = true
        tf.backgroundColor = NSColor.white.withAlphaComponent(0.85)
        tf.textColor = currentColor
        tf.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        tf.focusRingType = .none
        tf.placeholderString = "Type text…"
        tf.delegate = self
        addSubview(tf)
        window?.makeFirstResponder(tf)
        pendingTextField = tf
    }

    private func commitPendingTextField() {
        guard let tf = pendingTextField else { return }
        if !tf.stringValue.isEmpty {
            // y in flipped view: tf.frame.origin.y is top of field
            let origin = CGPoint(x: tf.frame.origin.x, y: tf.frame.origin.y + tf.frame.height - 4)
            let shape = TextShape(origin: origin, text: tf.stringValue, color: currentColor)
            annotations.append(shape)
        }
        tf.removeFromSuperview()
        pendingTextField = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            pendingTextField?.removeFromSuperview()
            pendingTextField = nil
            currentShape = nil
            dragStart = nil
            needsDisplay = true
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        baseImage?.draw(in: bounds)
        for shape in annotations {
            shape.draw(baseImage: baseImage)
        }
        currentShape?.draw(baseImage: baseImage)
    }

    // MARK: - Export

    /// Render the canvas (image + annotations) to a full-resolution NSImage.
    func renderToImage() -> NSImage {
        guard let base = baseImage else { return NSImage() }
        let imageSize = base.size

        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(imageSize.width),
            pixelsHigh: Int(imageSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return base }

        guard let ctx = NSGraphicsContext(bitmapImageRep: bitmapRep) else { return base }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx

        // Flip context to match our flipped view (y=0 at top)
        ctx.cgContext.translateBy(x: 0, y: imageSize.height)
        ctx.cgContext.scaleBy(x: 1, y: -1)

        // Scale from canvas coords to image pixel coords
        let sx = imageSize.width / bounds.width
        let sy = imageSize.height / bounds.height
        ctx.cgContext.scaleBy(x: sx, y: sy)

        // Draw base image (in this context, y=0 is now at bottom again after the flip above,
        // so draw into the unscaled rect which is already in canvas coordinates)
        base.draw(in: NSRect(origin: .zero, size: bounds.size))

        for shape in annotations {
            shape.draw(baseImage: base)
        }

        NSGraphicsContext.restoreGraphicsState()

        let result = NSImage(size: imageSize)
        result.addRepresentation(bitmapRep)
        return result
    }

    // MARK: - Helpers

    private func makeRect(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(
            x: min(a.x, b.x), y: min(a.y, b.y),
            width: abs(b.x - a.x), height: abs(b.y - a.y)
        )
    }
}

// MARK: - NSTextFieldDelegate

extension AnnotationCanvasView: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) ||
           commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            commitPendingTextField()
            return true
        }
        return false
    }
}
