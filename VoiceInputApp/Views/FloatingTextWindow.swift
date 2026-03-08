import SwiftUI
import AppKit

class FloatingTextWindow: NSWindow {
    private var hostingView: NSHostingView<FloatingContentView>?
    private var viewModel = FloatingViewModel()

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 70),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.isMovableByWindowBackground = false
        self.ignoresMouseEvents = true
        self.hasShadow = false
        self.alphaValue = 1.0

        // 创建 SwiftUI 视图
        let contentView = FloatingContentView(viewModel: viewModel)
        hostingView = NSHostingView(rootView: contentView)
        self.contentView = hostingView

        print("✅ FloatingTextWindow initialized")
    }

    func show(text: String, mode: VoiceInputMode = .holdToTalk) {
        print("🪟 FloatingWindow.show() called with text: '\(text)', mode: \(mode)")
        viewModel.displayText = text
        viewModel.mode = mode
        viewModel.isRecording = true
        viewModel.showComplete = false
        positionWindow()
        if !isVisible {
            makeKeyAndOrderFront(nil)
            print("🪟 FloatingWindow now visible")
        }
    }

    func hide() {
        print("🪟 FloatingWindow.hide() called")
        viewModel.isRecording = false
        viewModel.displayText = ""
        viewModel.showComplete = false
        orderOut(nil)
    }

    func updateText(_ text: String) {
        print("🪟 FloatingWindow.updateText() called with: '\(text)'")
        // 直接显示最新的文字
        viewModel.displayText = text
        viewModel.showComplete = false
    }

    func showComplete(_ text: String = "✓ 复制已完成") {
        print("🪟 FloatingWindow.showComplete() called")
        viewModel.isRecording = false
        viewModel.displayText = text
        viewModel.showComplete = true

        // 1.5秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.hide()
        }
    }

    func setMode(_ mode: VoiceInputMode) {
        viewModel.mode = mode
    }

    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        // 固定窗口大小
        let windowWidth: CGFloat = 550
        let windowHeight: CGFloat = 70

        // 位置：屏幕底部中央，往上80像素
        let x = (screenFrame.width - windowWidth) / 2 + screenFrame.origin.x
        let y = screenFrame.origin.y + 80

        setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }
}

// MARK: - ViewModel
class FloatingViewModel: ObservableObject {
    @Published var displayText: String = ""
    @Published var mode: VoiceInputMode = .holdToTalk
    @Published var isRecording: Bool = false
    @Published var showComplete: Bool = false
}

// MARK: - SwiftUI View
struct FloatingContentView: View {
    @ObservedObject var viewModel: FloatingViewModel

    var body: some View {
        HStack(spacing: 14) {
            // 状态图标
            if viewModel.showComplete {
                // 完成图标
                CompleteIcon()
            } else {
                // 录音指示器 - 只显示一个带音波效果的红色麦克风
                RecordingIndicator()
            }

            // 识别文字 - 头部截断，显示最新内容
            Text(viewModel.displayText.isEmpty ? "正在聆听..." : viewModel.displayText)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(viewModel.showComplete ? .green : .white)
                .lineLimit(1)
                .truncationMode(.head)
                .shadow(color: viewModel.showComplete ? .green.opacity(0.5) : .cyan.opacity(0.5), radius: 2, x: 0, y: 0)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                // 主背景 - 深色半透明
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.05, green: 0.08, blue: 0.15),
                                Color(red: 0.1, green: 0.15, blue: 0.25)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 边框发光效果
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: viewModel.showComplete ? [
                                Color.green.opacity(0.6),
                                Color.green.opacity(0.4),
                                Color.green.opacity(0.6)
                            ] : [
                                Color.cyan.opacity(0.6),
                                Color.purple.opacity(0.4),
                                Color.cyan.opacity(0.6)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )

                // 内部光晕
                RoundedRectangle(cornerRadius: 16)
                    .stroke(viewModel.showComplete ? Color.green.opacity(0.2) : Color.cyan.opacity(0.2), lineWidth: 1)
                    .blur(radius: 4)
            }
        )
        .shadow(color: viewModel.showComplete ? Color.green.opacity(0.3) : Color.cyan.opacity(0.3), radius: 20, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

// MARK: - 录音指示器 - 带音波效果的红色麦克风
struct RecordingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 音波扩散效果
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        Color.red.opacity(0.4 - Double(i) * 0.12),
                        lineWidth: 2
                    )
                    .frame(width: 28 + CGFloat(i * 10), height: 28 + CGFloat(i * 10))
                    .scaleEffect(isAnimating ? 1.4 : 1.0)
                    .opacity(isAnimating ? 0 : 0.7)
                    .animation(
                        Animation.easeOut(duration: 1.2)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.25),
                        value: isAnimating
                    )
            }

            // 麦克风图标
            Image(systemName: "mic.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .shadow(color: .red.opacity(0.8), radius: 3, x: 0, y: 0)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 完成图标
struct CompleteIcon: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 外圈
            Circle()
                .stroke(Color.green.opacity(0.4), lineWidth: 2)
                .frame(width: 32, height: 32)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )

            // 背景
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.green,
                            Color.green.opacity(0.6)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 24, height: 24)

            // 勾选图标
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: .green.opacity(0.6), radius: 4, x: 0, y: 0)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 模式图标
struct ModeIcon: View {
    let mode: VoiceInputMode

    var body: some View {
        ZStack {
            // 背景圆
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.3),
                            Color.purple.opacity(0.2)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 16
                    )
                )
                .frame(width: 32, height: 32)

            // 图标
            if mode == .holdToTalk {
                // 麦克风图标
                Image(systemName: "mic.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cyan)
            } else {
                // 连续模式图标
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.purple)
            }
        }
        .shadow(color: .cyan.opacity(0.5), radius: 3, x: 0, y: 0)
    }
}