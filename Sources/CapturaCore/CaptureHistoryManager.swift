import Cocoa

struct HistoryItem {
    let id: UUID = UUID()
    let image: NSImage
    let date: Date
}

class CaptureHistoryManager {
    static let shared = CaptureHistoryManager()
    private init() {}

    private(set) var items: [HistoryItem] = []
    var onItemAdded: (() -> Void)?

    func add(_ image: NSImage) {
        let item = HistoryItem(image: image, date: Date())
        items.insert(item, at: 0)
        if items.count > 20 { items.removeLast() }
        DispatchQueue.main.async { self.onItemAdded?() }
    }

    func clear() {
        items = []
        DispatchQueue.main.async { self.onItemAdded?() }
    }

    func thumbnail(for item: HistoryItem, size: CGSize = CGSize(width: 80, height: 50)) -> NSImage {
        let thumb = NSImage(size: size)
        thumb.lockFocus()
        item.image.draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        thumb.unlockFocus()
        return thumb
    }
}
