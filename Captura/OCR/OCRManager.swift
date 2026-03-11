import Cocoa
import Vision

enum OCRManager {
    static func recognizeText(in image: NSImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion([])
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                guard error == nil else {
                    completion([])
                    return
                }

                let results = request.results as? [VNRecognizedTextObservation] ?? []
                let texts = results.compactMap { $0.topCandidates(1).first?.string }
                completion(texts)
            }
        }

        request.recognitionLanguages = ["fr", "en"]
        request.usesLanguageCorrection = true

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            completion([])
        }
    }
}
