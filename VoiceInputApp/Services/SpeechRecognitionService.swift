import Foundation
import Speech
import AVFoundation

protocol SpeechRecognitionServiceDelegate: AnyObject {
    func didRecognizeText(_ result: VoiceRecognitionResult)
    func didChangeState(_ state: SpeechRecognitionState)
    func didOccurError(_ error: Error)
}

enum SpeechRecognitionState {
    case idle
    case listening
    case processing
}

class SpeechRecognitionService: NSObject, ObservableObject {
    weak var delegate: SpeechRecognitionServiceDelegate?

    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    @Published var state: SpeechRecognitionState = .idle
    @Published var isAvailable: Bool = true

    private var lastRecognizedText: String = ""
    private var isStopping: Bool = false

    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        checkAvailability()
    }

    private func checkAvailability() {
        guard let recognizer = speechRecognizer else {
            isAvailable = false
            return
        }

        isAvailable = recognizer.isAvailable
        recognizer.delegate = self

        print("Speech recognizer available: \(recognizer.isAvailable)")
    }

    func startRecording() throws {
        // Reset state
        lastRecognizedText = ""
        isStopping = false

        // Check authorization
        let status = SFSpeechRecognizer.authorizationStatus()
        print("Speech recognition status: \(status.rawValue)")

        guard status == .authorized else {
            print("Speech recognition not authorized!")
            throw SpeechError.notAuthorized
        }

        // Check if audio engine is already running
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Setup recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true
        recognitionRequest.taskHint = .dictation

        // Setup audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        print("Starting speech recognition...")
        print("Recording format: \(recordingFormat)")

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let text = result.bestTranscription.formattedString
                self.lastRecognizedText = text

                print("Recognized text: \(text), isFinal: \(result.isFinal)")

                let confidence = result.bestTranscription.segments.last?.confidence ?? 1.0

                let recognitionResult = VoiceRecognitionResult(
                    text: text,
                    isFinal: result.isFinal,
                    confidence: confidence
                )

                self.delegate?.didRecognizeText(recognitionResult)
            }

            if let error = error {
                print("Recognition error: \(error.localizedDescription)")
                // Don't notify delegate for minor errors
                if (error as NSError).code != 216 {
                    // Only notify for significant errors
                }
            }
        }

        // Install audio tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        print("Audio engine started")

        state = .listening
        delegate?.didChangeState(.listening)
    }

    func stopRecording() {
        guard !isStopping else { return }
        isStopping = true

        print("Stopping recording...")

        // First, end audio input
        recognitionRequest?.endAudio()

        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        state = .processing
        delegate?.didChangeState(.processing)

        // Wait a bit for final results, then finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            print("Final text: \(self.lastRecognizedText)")

            // Send final result if we have text
            if !self.lastRecognizedText.isEmpty {
                let finalResult = VoiceRecognitionResult(
                    text: self.lastRecognizedText,
                    isFinal: true,
                    confidence: 1.0
                )
                self.delegate?.didRecognizeText(finalResult)
            }

            // Clean up
            self.recognitionTask?.finish()
            self.recognitionTask = nil
            self.recognitionRequest = nil

            self.state = .idle
            self.delegate?.didChangeState(.idle)

            print("Recording stopped completely")
        }
    }

    func cancel() {
        isStopping = true
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        lastRecognizedText = ""
        state = .idle
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ recognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isAvailable = available
            print("Speech recognizer availability changed: \(available)")
        }
    }
}

// MARK: - Errors
enum SpeechError: LocalizedError {
    case notAuthorized
    case requestCreationFailed
    case audioEngineStartFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "语音识别权限未授权"
        case .requestCreationFailed:
            return "无法创建识别请求"
        case .audioEngineStartFailed:
            return "音频引擎启动失败"
        }
    }
}