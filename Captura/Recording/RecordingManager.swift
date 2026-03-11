import Cocoa
import ScreenCaptureKit
import AVFoundation
import UserNotifications

class RecordingManager: NSObject {
    static let shared = RecordingManager()
    private override init() { super.init() }

    private(set) var isRecording = false
    var onStateChanged: ((Bool) -> Void)?

    private var stream: SCStream?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var startTime: CMTime?
    private var outputURL: URL?
    private let queue = DispatchQueue(label: "com.captura.recording", qos: .userInitiated)

    // MARK: - Start

    func startRecording(completion: @escaping (Error?) -> Void) {
        guard !isRecording else { return }

        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { [weak self] content, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async { completion(error) }
                return
            }

            guard let display = content?.displays.first else {
                DispatchQueue.main.async {
                    completion(NSError(domain: "Captura", code: 1, userInfo: [NSLocalizedDescriptionKey: "No display found"]))
                }
                return
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])

            let config = SCStreamConfiguration()
            config.width = display.width * 2   // retina
            config.height = display.height * 2
            config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
            config.queueDepth = 6
            config.showsCursor = true

            let timestamp = Int(Date().timeIntervalSince1970)
            let url = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop")
                .appendingPathComponent("recording-\(timestamp).mp4")
            self.outputURL = url

            do {
                let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)

                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: display.width * 2,
                    AVVideoHeightKey: display.height * 2,
                    AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: 8_000_000,
                        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                    ]
                ]

                let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                input.expectsMediaDataInRealTime = true

                let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: input,
                    sourcePixelBufferAttributes: nil
                )

                writer.add(input)
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)

                self.assetWriter = writer
                self.videoInput = input
                self.adaptor = adaptor
                self.startTime = nil

                let streamOut = RecordingStreamOutput(manager: self)
                let scStream = SCStream(filter: filter, configuration: config, delegate: streamOut)
                try scStream.addStreamOutput(streamOut, type: .screen, sampleHandlerQueue: self.queue)

                scStream.startCapture { [weak self] err in
                    DispatchQueue.main.async {
                        if let err = err {
                            self?.isRecording = false
                            completion(err)
                        } else {
                            self?.stream = scStream
                            self?.isRecording = true
                            self?.onStateChanged?(true)
                            completion(nil)
                        }
                    }
                }

            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }

    // MARK: - Stop

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        stream?.stopCapture { [weak self] _ in
            guard let self = self else { return }
            self.videoInput?.markAsFinished()
            self.assetWriter?.finishWriting {
                DispatchQueue.main.async {
                    self.onStateChanged?(false)
                    self.postNotification()
                    self.stream = nil
                    self.assetWriter = nil
                    self.videoInput = nil
                    self.adaptor = nil
                    self.startTime = nil
                }
            }
        }
    }

    // MARK: - Frame writing (called from RecordingStreamOutput)

    func handleSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isRecording,
              let input = videoInput, input.isReadyForMoreMediaData,
              let adaptor = adaptor else { return }

        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if startTime == nil { startTime = pts }
        let adjusted = CMTimeSubtract(pts, startTime!)

        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            adaptor.append(pixelBuffer, withPresentationTime: adjusted)
        }
    }

    // MARK: - Notification

    private func postNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Recording Saved"
            content.body = "Saved to Desktop as MP4"
            let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(req)
        }
    }
}

// MARK: - SCStreamOutput + SCStreamDelegate (separate object to avoid circular retain)

private class RecordingStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    weak var manager: RecordingManager?
    init(manager: RecordingManager) { self.manager = manager }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        manager?.handleSampleBuffer(sampleBuffer)
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async {
            if self.manager?.isRecording == true {
                self.manager?.stopRecording()
            }
        }
    }
}
