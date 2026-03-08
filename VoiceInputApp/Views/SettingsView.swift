import SwiftUI
import Carbon

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var editingIndex: Int?
    @State private var editingKeyword: String = ""
    @State private var editingAction: KeyboardAction = .enter
    @State private var showingAddSheet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text("设置")
                    .font(.headline)

                Spacer()

                // 占位，保持标题居中
                Text("返回")
                    .opacity(0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // 设置内容
            TabView {
                // 关键词设置 Tab
            VStack(spacing: 0) {
                List {
                    Section {
                        ForEach(viewModel.keywordActions.indices, id: \.self) { index in
                            HStack(spacing: 12) {
                                // 关键词标签
                                Text(viewModel.keywordActions[index].keyword)
                                    .font(.body)

                                Spacer()

                                // 操作描述
                                Label(viewModel.keywordActions[index].action.displayName, systemImage: viewModel.keywordActions[index].action.icon)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)

                                // 编辑按钮
                                Button {
                                    editingIndex = index
                                    editingKeyword = viewModel.keywordActions[index].keyword
                                    editingAction = viewModel.keywordActions[index].action
                                    showingAddSheet = true
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)

                                // 删除按钮
                                Button {
                                    viewModel.removeKeywordAction(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text("关键词 → 操作")
                    } footer: {
                        HStack {
                            Button {
                                editingKeyword = ""
                                editingAction = .enter
                                editingIndex = nil
                                showingAddSheet = true
                            } label: {
                                Label("添加关键词", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)

                            Spacer()

                            Button("恢复默认") {
                                viewModel.resetToDefaults()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                        .padding(.top, 8)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
            .tabItem {
                Label("关键词", systemImage: "text.bubble")
            }

            // 通用设置 Tab
            Form {
                Section {
                    HStack {
                        Text("触发语音按键")
                        Spacer()
                        TriggerKeyInputView(keys: $viewModel.triggerKeys)
                            .frame(width: 180, height: 32)
                    }

                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("单键为长按模式，组合键为连续模式")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("快捷键")
                }

                Section {
                    Toggle("自动复制到剪贴板", isOn: $viewModel.autoCopyToClipboard)
                    Toggle("显示通知", isOn: $viewModel.showNotification)
                } header: {
                    Text("选项")
                }

                Section {
                    LabeledContent {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } label: {
                        Label("麦克风", systemImage: "mic.fill")
                    }

                    LabeledContent {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } label: {
                        Label("语音识别", systemImage: "waveform")
                    }

                    LabeledContent {
                        Image(systemName: AXIsProcessTrusted() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(AXIsProcessTrusted() ? .green : .orange)
                    } label: {
                        Label("辅助功能", systemImage: "keyboard")
                    }
                } header: {
                    Text("权限")
                } footer: {
                    if !AXIsProcessTrusted() {
                        Text("请在系统偏好设置中授权辅助功能")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("通用", systemImage: "gearshape")
            }
        }
        }
        .frame(width: 420, height: 520)
        .sheet(isPresented: $showingAddSheet) {
            KeywordEditSheet(
                keyword: $editingKeyword,
                action: $editingAction,
                title: editingIndex == nil ? "添加关键词" : "编辑关键词",
                onSave: {
                    if !editingKeyword.isEmpty {
                        if let index = editingIndex {
                            viewModel.updateKeywordAction(at: index, keyword: editingKeyword, action: editingAction)
                        } else {
                            viewModel.addKeywordAction(keyword: editingKeyword, action: editingAction)
                        }
                        showingAddSheet = false
                        editingIndex = nil
                    }
                },
                onCancel: {
                    showingAddSheet = false
                    editingIndex = nil
                }
            )
        }
    }
}

// MARK: - 关键词编辑弹窗
struct KeywordEditSheet: View {
    @Binding var keyword: String
    @Binding var action: KeyboardAction
    let title: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @FocusState private var isKeywordFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)

            Form {
                TextField("关键词", text: $keyword, prompt: Text("例如：结束"))
                    .focused($isKeywordFocused)

                Picker("键盘操作", selection: $action) {
                    ForEach(KeyboardAction.allCases, id: \.self) { act in
                        Label(act.displayName, systemImage: act.icon)
                            .tag(act)
                    }
                }
            }
            .formStyle(.grouped)
            .frame(height: 120)

            HStack {
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("保存") {
                    onSave()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(keyword.isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
    }
}

// MARK: - 触发快捷键输入视图
struct TriggerKeyInputView: NSViewRepresentable {
    @Binding var keys: [String]

    func makeNSView(context: Context) -> StyledKeyInputView {
        let view = StyledKeyInputView()
        view.keys = keys
        view.onKeysChanged = { newKeys in
            DispatchQueue.main.async {
                self.keys = newKeys
            }
        }
        return view
    }

    func updateNSView(_ nsView: StyledKeyInputView, context: Context) {
        nsView.keys = keys
        nsView.updateDisplay()
    }
}

// MARK: - 快捷键输入视图
class StyledKeyInputView: NSView {
    var keys: [String] = []
    var onKeysChanged: (([String]) -> Void)?

    private var isRecording = false
    private var recordedKeyCodes: Set<UInt16> = []
    private var keyLabels: [NSView] = []
    private var containerBox: NSBox!
    private var eventMonitor: Any?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true

        // 创建容器 - 使用系统风格
        containerBox = NSBox(frame: NSRect(x: 0, y: 0, width: 180, height: 32))
        containerBox.boxType = .custom
        containerBox.fillColor = NSColor.textBackgroundColor
        containerBox.isTransparent = false
        containerBox.cornerRadius = 6
        containerBox.borderWidth = 1
        containerBox.borderColor = NSColor.separatorColor
        addSubview(containerBox)

        updateDisplay()

        // 添加点击手势
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        addGestureRecognizer(clickGesture)
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 180, height: 32)
    }

    @objc private func handleClick() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        recordedKeyCodes.removeAll()

        // 高亮显示
        containerBox.borderColor = NSColor.controlAccentColor
        containerBox.fillColor = NSColor.textBackgroundColor

        // 清除现有标签，显示提示
        clearKeyLabels()

        let label = createHintLabel("按下快捷键...")
        containerBox.addSubview(label)
        keyLabels.append(label)

        // 监听键盘事件
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecording else { return }

        // 检测 FN 键
        if event.modifierFlags.contains(.function) {
            recordedKeyCodes.insert(63)
        }

        // 记录普通按键
        if event.type == .keyDown {
            recordedKeyCodes.insert(event.keyCode)
        }

        updateKeysFromCodes()
    }

    private func updateKeysFromCodes() {
        var newKeys: [String] = []

        if recordedKeyCodes.contains(63) {
            newKeys.append("FN")
        }

        for keyCode in recordedKeyCodes.sorted() {
            if keyCode == 63 { continue }
            if let keyName = keyNameForCode(keyCode) {
                newKeys.append(keyName)
            }
        }

        keys = newKeys
        onKeysChanged?(keys)

        // 自动停止录制
        if !keys.isEmpty {
            stopRecording()
        }
    }

    private func stopRecording() {
        isRecording = false
        containerBox.borderColor = NSColor.separatorColor
        containerBox.fillColor = NSColor.textBackgroundColor

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        updateDisplay()
    }

    func updateDisplay() {
        clearKeyLabels()

        if keys.isEmpty {
            // 显示占位提示
            let label = createCenteredLabel("点击设置快捷键", textColor: .placeholderTextColor)
            containerBox.addSubview(label)
            keyLabels.append(label)
        } else {
            // 显示按键 - 直接文本显示，居中
            let keyText = keys.joined(separator: " + ")
            let label = createCenteredLabel(keyText, textColor: .labelColor, fontWeight: .medium)
            containerBox.addSubview(label)
            keyLabels.append(label)
        }
    }

    private func createCenteredLabel(_ text: String, textColor: NSColor, fontWeight: NSFont.Weight = .regular) -> NSTextField {
        let label = NSTextField(frame: containerBox.bounds)
        label.stringValue = text
        label.font = NSFont.systemFont(ofSize: 13, weight: fontWeight)
        label.textColor = textColor
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.alignment = .center
        label.usesSingleLineMode = true

        // 强制布局以获取正确的文字尺寸
        label.sizeToFit()

        // 计算居中位置
        let textHeight = label.frame.height
        let containerHeight = containerBox.bounds.height
        let yOffset = (containerHeight - textHeight) / 2

        // 设置新的frame，保持容器宽度，垂直居中
        label.frame = NSRect(x: 0, y: yOffset, width: containerBox.bounds.width, height: textHeight)

        return label
    }

    private func createHintLabel(_ text: String) -> NSTextField {
        return createCenteredLabel(text, textColor: .placeholderTextColor)
    }

    private func clearKeyLabels() {
        for label in keyLabels {
            label.removeFromSuperview()
        }
        keyLabels.removeAll()
    }

    private func keyNameForCode(_ code: UInt16) -> String? {
        switch Int(code) {
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Escape: return "Esc"
        case kVK_Delete: return "Delete"
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        default: return nil
        }
    }
}

#Preview {
    SettingsView()
}