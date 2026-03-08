import Foundation

struct VoiceRecognitionResult {
    let text: String
    let isFinal: Bool
    let confidence: Float

    init(text: String, isFinal: Bool = false, confidence: Float = 1.0) {
        self.text = text
        self.isFinal = isFinal
        self.confidence = confidence
    }
}