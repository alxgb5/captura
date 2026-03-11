import Foundation

enum FilenameGenerator {
    static let defaultTemplate = "screenshot-{date}-{time}"

    static func generate(template: String = defaultTemplate, fileExtension: String = "png") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: Date())

        formatter.dateFormat = "HH-mm-ss"
        let time = formatter.string(from: Date())

        var filename = template
            .replacingOccurrences(of: "{date}", with: date)
            .replacingOccurrences(of: "{time}", with: time)

        if !filename.hasSuffix(".\(fileExtension)") {
            filename.append(".\(fileExtension)")
        }

        return filename
    }

    static func generate(template: String = defaultTemplate) -> String {
        generate(template: template, fileExtension: "png")
    }
}
