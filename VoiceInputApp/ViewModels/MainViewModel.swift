import Foundation
import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    // Services
    private var speechService: SpeechRecognitionService
    private var keyboardService: KeyboardService
    private var clipboardService: ClipboardService
    private var hotkeyService: HotkeyService
    private var keywordProcessor: KeywordProcessor

    // Floating window
    private var floatingWindow: FloatingTextWindow?

    private let settings = AppSettings.shared

    // Published state
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var statusMessage: String = "按住快捷键开始录音"
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var currentMode: VoiceInputMode = .holdToTalk

    private var cancellables = Set<AnyCancellable>()
    private var hasProcessedResult: Bool = false

    init() {
        speechService = SpeechRecognitionService()
        keyboardService = KeyboardService.shared
        clipboardService = ClipboardService.shared
        hotkeyService = HotkeyService()
        keywordProcessor = KeywordProcessor()

        setupBindings()
    }

    func setupServices() {
        speechService.delegate = self
        hotkeyService.delegate = self

        // 加载自定义触发键
        hotkeyService.updateTriggerKeys(settings.triggerKeys)

        hotkeyService.startMonitoring()

        // Initialize floating window
        floatingWindow = FloatingTextWindow()

        print("MainViewModel services setup complete")
    }

    private func setupBindings() {
        // 监听关键词设置变化
        settings.$keywordActions
            .sink { [weak self] actions in
                self?.keywordProcessor.updateKeywordActions(actions)
            }
            .store(in: &cancellables)

        // 监听触发键设置变化
        settings.$triggerKeys
            .sink { [weak self] keys in
                self?.hotkeyService.updateTriggerKeys(keys)
                self?.updateStatusMessage()
            }
            .store(in: &cancellables)
    }

    private func updateStatusMessage() {
        let keys = settings.triggerKeys.joined(separator: " + ")
        statusMessage = "按住 \(keys) 开始录音"
    }

    func startRecording(mode: VoiceInputMode) {
        print("🎬 Starting recording with mode: \(mode)")

        do {
            recognizedText = ""
            hasProcessedResult = false
            currentMode = mode
            try speechService.startRecording()
            isRecording = true

            // Show floating window with mode
            floatingWindow?.show(text: "", mode: mode)

            switch mode {
            case .holdToTalk:
                statusMessage = "🎤 长按模式：松开结束"
            case .continuous:
                statusMessage = "🎤 连续模式：说\"结束\"完成"
            }
        } catch {
            print("❌ Error starting recording: \(error)")
            showError = true
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() {
        print("🛑 Stopping recording...")
        speechService.stopRecording()
        isRecording = false
        statusMessage = "处理中..."
    }

    private func processAndInputText(_ text: String) {
        guard !hasProcessedResult else {
            print("⚠️ Already processed, skipping duplicate")
            return
        }
        hasProcessedResult = true

        guard !text.isEmpty else {
            print("⚠️ Empty text, skipping")
            floatingWindow?.hide()
            return
        }

        print("📝 Processing text: '\(text)'")

        let endKeywordDetected = text.contains("结束")

        var (remainingText, actions) = keywordProcessor.processText(text)

        if currentMode == .continuous && endKeywordDetected {
            remainingText = remainingText.replacingOccurrences(of: "结束", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

            if !actions.contains(where: { $0 == .enter }) {
                actions.append(.enter)
            }
        }

        if !remainingText.isEmpty {
            print("⌨️ Typing text to input field: \(remainingText)")
            keyboardService.typeText(remainingText)

            if settings.autoCopyToClipboard {
                clipboardService.copyToClipboard(remainingText)
                print("📋 Copied to clipboard: \(remainingText)")
            }

            statusMessage = "✓ 已输入: \(remainingText)"
        }

        for (index, action) in actions.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + Double(index) * 0.05) {
                print("🎹 Performing action: \(action)")
                self.keyboardService.performAction(action)
            }
        }

        if !actions.isEmpty {
            statusMessage = "✓ 执行了 \(actions.count) 个操作"
        }

        if remainingText.isEmpty && actions.isEmpty {
            statusMessage = "未识别到有效内容"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            if !remainingText.isEmpty {
                self?.floatingWindow?.showComplete("✓ 复制已完成")
            } else {
                self?.floatingWindow?.hide()
            }
        }
    }

    func cleanup() {
        hotkeyService.stopMonitoring()
        floatingWindow?.close()
        if isRecording {
            speechService.cancel()
        }
    }
}

// MARK: - SpeechRecognitionServiceDelegate
extension MainViewModel: SpeechRecognitionServiceDelegate {
    func didRecognizeText(_ result: VoiceRecognitionResult) {
        self.recognizedText = result.text
        self.floatingWindow?.updateText(result.text)

        print("🎤 Recognized: '\(result.text)' isFinal: \(result.isFinal), hasProcessed: \(self.hasProcessedResult)")

        if result.isFinal && !self.hasProcessedResult {
            self.processAndInputText(result.text)
        } else if self.currentMode == .continuous && result.text.contains("结束") && !self.hasProcessedResult {
            self.processAndInputText(result.text)
            self.stopRecording()
        } else {
            self.statusMessage = "🎤 正在识别: \(result.text)"
        }
    }

    func didChangeState(_ state: SpeechRecognitionState) {
        print("🎙️ State changed to: \(state)")

        switch state {
        case .idle:
            self.isRecording = false
            self.updateStatusMessage()

        case .listening:
            self.isRecording = true
            switch self.currentMode {
            case .holdToTalk:
                self.statusMessage = "🎤 长按模式：松开结束"
            case .continuous:
                self.statusMessage = "🎤 连续模式：说\"结束\"完成"
            }

        case .processing:
            self.statusMessage = "处理中..."
        }
    }

    func didOccurError(_ error: Error) {
        print("❌ Speech error: \(error)")
        self.showError = true
        self.errorMessage = error.localizedDescription
        self.statusMessage = "错误: \(error.localizedDescription)"
        self.floatingWindow?.hide()
    }
}

// MARK: - HotkeyServiceDelegate
extension MainViewModel: HotkeyServiceDelegate {
    func hotkeyDidPress() {
        print("🔥 Hotkey pressed, isRecording: \(self.isRecording)")
        if !self.isRecording {
            let mode = self.hotkeyService.mode
            self.startRecording(mode: mode)
        }
    }

    func hotkeyDidRelease() {
        print("🔥 Hotkey released, isRecording: \(self.isRecording), mode: \(self.currentMode)")

        if self.isRecording && self.currentMode == .holdToTalk {
            // 立即隐藏悬浮窗口
            self.floatingWindow?.hide()
            self.stopRecording()
        }
    }
}