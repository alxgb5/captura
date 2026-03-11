import Foundation
import Cocoa

// MARK: - Mini test framework
var passed = 0
var failed = 0

func test(_ name: String, _ block: () throws -> Void) {
    do {
        try block()
        print("  ✅ \(name)")
        passed += 1
    } catch {
        print("  ❌ \(name): \(error)")
        failed += 1
    }
}

func expect(_ condition: Bool, _ message: String = "Assertion failed") throws {
    if !condition { throw TestError.failed(message) }
}

func expectEqual<T: Equatable>(_ a: T, _ b: T, _ message: String? = nil) throws {
    if a != b { throw TestError.failed(message ?? "Expected \(a) == \(b)") }
}

enum TestError: Error { case failed(String) }

func section(_ name: String) { print("\n── \(name) ──") }

func makeTestImage(size: NSSize = NSSize(width: 20, height: 20), color: NSColor = .red) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    color.setFill()
    NSRect(origin: .zero, size: size).fill()
    image.unlockFocus()
    return image
}

// MARK: - CaptureHistoryManager Tests
section("CaptureHistoryManager")
let hm = CaptureHistoryManager.shared

test("starts empty") {
    hm.clear()
    try expectEqual(hm.items.count, 0)
}

test("adds capture") {
    hm.clear()
    hm.add(makeTestImage())
    try expectEqual(hm.items.count, 1)
}

test("limits to 20 items") {
    hm.clear()
    for _ in 0..<25 { hm.add(makeTestImage()) }
    try expectEqual(hm.items.count, 20)
}

test("FIFO — drops oldest") {
    hm.clear()
    for i in 0..<21 { hm.add(makeTestImage(size: NSSize(width: CGFloat(i+1), height: 10))) }
    try expect(hm.items.first?.image.size.width == 21, "Newest should be first")
    try expect(hm.items.first(where: { $0.image.size.width == 1 }) == nil, "Oldest should be dropped")
}

test("clear resets count") {
    hm.add(makeTestImage())
    hm.clear()
    try expectEqual(hm.items.count, 0)
}

test("item has valid date") {
    hm.clear()
    let before = Date()
    hm.add(makeTestImage())
    guard let item = hm.items.first else { throw TestError.failed("No item") }
    try expect(item.date >= before, "Date should be recent")
}

// MARK: - FilenameGenerator Tests
section("FilenameGenerator")

test("default starts with 'screenshot-'") {
    try expect(FilenameGenerator.generate().hasPrefix("screenshot-"))
}

test("default ends with '.png'") {
    try expect(FilenameGenerator.generate().hasSuffix(".png"))
}

test("custom extension .jpg") {
    let n = FilenameGenerator.generate(template: "cap", fileExtension: "jpg")
    try expect(n.hasSuffix(".jpg"), "Got: \(n)")
}

test("{date} token replaced") {
    let n = FilenameGenerator.generate(template: "{date}")
    try expect(!n.contains("{date}"), "Token not replaced: \(n)")
}

test("{time} token replaced") {
    let n = FilenameGenerator.generate(template: "{time}")
    try expect(!n.contains("{time}"), "Token not replaced: \(n)")
}

test("no tokens passthrough") {
    try expectEqual(FilenameGenerator.generate(template: "myfile", fileExtension: "png"), "myfile.png")
}

test("extension not doubled") {
    try expectEqual(FilenameGenerator.generate(template: "file.png", fileExtension: "png"), "file.png")
}

// MARK: - ImageExporter Tests
section("ImageExporter")
let img = makeTestImage()

test("export PNG not nil") {
    try expect(ImageExporter.export(img, as: .png) != nil)
}

test("PNG magic bytes 0x89 0x50 0x4E 0x47") {
    guard let d = ImageExporter.export(img, as: .png) else { throw TestError.failed("nil") }
    let b = [UInt8](d.prefix(4))
    try expect(b[0]==0x89 && b[1]==0x50 && b[2]==0x4E && b[3]==0x47)
}

test("export JPEG not nil") {
    try expect(ImageExporter.export(img, as: .jpeg(quality: 0.8)) != nil)
}

test("JPEG magic bytes 0xFF 0xD8") {
    guard let d = ImageExporter.export(img, as: .jpeg(quality: 0.8)) else { throw TestError.failed("nil") }
    let b = [UInt8](d.prefix(2))
    try expect(b[0]==0xFF && b[1]==0xD8)
}

test("export TIFF not nil") {
    try expect(ImageExporter.export(img, as: .tiff) != nil)
}

test("JPEG quality 1.0 > quality 0.1 in size") {
    guard let hi = ImageExporter.export(img, as: .jpeg(quality: 1.0)),
          let lo = ImageExporter.export(img, as: .jpeg(quality: 0.1)) else { throw TestError.failed("nil") }
    try expect(hi.count > lo.count, "hi=\(hi.count) lo=\(lo.count)")
}

test("exportToFile writes file to disk") {
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("captura_test_\(UUID().uuidString).png")
    try expect(ImageExporter.exportToFile(img, at: url, as: .png))
    try expect(FileManager.default.fileExists(atPath: url.path))
    try? FileManager.default.removeItem(at: url)
}

// MARK: - PreferencesManager Tests
section("PreferencesManager")
PreferencesManager.resetAll()

test("default showFloatingThumbnail = true") {
    PreferencesManager.resetAll()
    try expect(PreferencesManager.showFloatingThumbnail)
}

test("default includeWallpaper = true") {
    PreferencesManager.resetAll()
    try expect(PreferencesManager.includeWallpaper)
}

test("default appTheme = 0 (auto)") {
    PreferencesManager.resetAll()
    try expectEqual(PreferencesManager.appTheme, 0)
}

test("default imageFormat = PNG") {
    PreferencesManager.resetAll()
    try expectEqual(PreferencesManager.imageFormat, "PNG")
}

test("save/load appTheme") {
    PreferencesManager.appTheme = 2
    try expectEqual(PreferencesManager.appTheme, 2)
    PreferencesManager.resetAll()
}

test("save/load imageFormat") {
    PreferencesManager.imageFormat = "JPEG"
    try expectEqual(PreferencesManager.imageFormat, "JPEG")
    PreferencesManager.resetAll()
}

test("save/load thumbnail toggle") {
    PreferencesManager.showFloatingThumbnail = false
    try expect(!PreferencesManager.showFloatingThumbnail)
    PreferencesManager.resetAll()
}

test("resetAll restores defaults") {
    PreferencesManager.appTheme = 2
    PreferencesManager.imageFormat = "TIFF"
    PreferencesManager.resetAll()
    try expectEqual(PreferencesManager.appTheme, 0)
    try expectEqual(PreferencesManager.imageFormat, "PNG")
}

// MARK: - Results
print("\n────────────────────────────────────")
print("Results: \(passed + failed) tests — \(passed) passed, \(failed) failed")
if failed > 0 {
    print("❌ FAILED")
    exit(1)
} else {
    print("✅ ALL TESTS PASSED")
}
