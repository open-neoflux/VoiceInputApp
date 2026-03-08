import Foundation
import AppKit
import Carbon

protocol HotkeyServiceDelegate: AnyObject {
    func hotkeyDidPress()
    func hotkeyDidRelease()
}

enum VoiceInputMode {
    case holdToTalk      // 长按触发键，松开结束
    case continuous      // 连续模式，说"结束"关键词结束
}

class HotkeyService {
    weak var delegate: HotkeyServiceDelegate?

    private var eventMonitor: Any?
    private var isKeyPressed = false
    private var currentMode: VoiceInputMode = .holdToTalk

    // 当前配置的触发键
    private var triggerKeys: Set<String> = ["FN"]

    // 当前按下的键
    private var pressedKeys: Set<String> = []

    // FN 键状态
    private var fnKeyPressed = false

    // 长按计时器
    private var holdTimer: Timer?
    private let holdDuration: TimeInterval = 0.5  // 长按1秒触发
    private var hasTriggeredRecording = false  // 是否已触发录音

    var mode: VoiceInputMode {
        return currentMode
    }

    func updateTriggerKeys(_ keys: [String]) {
        triggerKeys = Set(keys.map { $0.uppercased() })
        print("🔧 Updated trigger keys: \(triggerKeys)")
    }

    func startMonitoring() {
        print("Starting hotkey monitoring...")

        // 监听所有键盘事件
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            self?.handleEvent(event)
        }

        print("Hotkey monitoring started")
    }

    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        holdTimer?.invalidate()
        holdTimer = nil
    }

    private func handleEvent(_ event: NSEvent) {
        let type = event.type

        switch type {
        case .flagsChanged:
            handleFlagsChanged(event)

        case .keyDown:
            handleKeyDown(event)

        case .keyUp:
            handleKeyUp(event)

        default:
            break
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        // 检测 FN 键状态
        let hasFunctionFlag = event.modifierFlags.contains(.function)
        let hasNumericPadFlag = event.modifierFlags.contains(.numericPad)
        let fnIsPressed = hasFunctionFlag || hasNumericPadFlag

        if fnIsPressed != fnKeyPressed {
            fnKeyPressed = fnIsPressed

            if fnKeyPressed {
                pressedKeys.insert("FN")
            } else {
                pressedKeys.remove("FN")
            }

            checkTriggerState()
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        let keyName = keyNameForCode(event.keyCode)
        if let name = keyName {
            pressedKeys.insert(name.uppercased())
            checkTriggerState()
        }
    }

    private func handleKeyUp(_ event: NSEvent) {
        let keyName = keyNameForCode(event.keyCode)
        if let name = keyName {
            pressedKeys.remove(name.uppercased())
            checkTriggerState()
        }
    }

    private func checkTriggerState() {
        // 检查是否所有触发键都被按下
        let allPressed = triggerKeys.isSubset(of: pressedKeys)

        print("🔑 Pressed: \(pressedKeys), Trigger: \(triggerKeys), AllPressed: \(allPressed), IsKeyPressed: \(isKeyPressed)")

        if allPressed && !isKeyPressed {
            // 所有触发键都被按下，开始计时
            isKeyPressed = true
            hasTriggeredRecording = false

            // 根据触发键数量决定模式
            if triggerKeys.count >= 2 {
                currentMode = .continuous
            } else {
                currentMode = .holdToTalk
            }

            // 启动长按计时器
            startHoldTimer()

        } else if !allPressed && isKeyPressed {
            // 触发键被释放
            isKeyPressed = false

            // 取消计时器
            holdTimer?.invalidate()
            holdTimer = nil

            // 只有已触发录音才通知释放
            if hasTriggeredRecording {
                print("🎤 Trigger keys released after recording")
                delegate?.hotkeyDidRelease()
            } else {
                print("🎤 Trigger keys released before hold duration - ignored")
            }

            hasTriggeredRecording = false
        }
    }

    private func startHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: holdDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.isKeyPressed && !self.hasTriggeredRecording {
                // 长按时间到达，触发录音
                self.hasTriggeredRecording = true
                print("🎤 Long press detected - starting \(self.currentMode == .holdToTalk ? "holdToTalk" : "continuous") mode")
                self.delegate?.hotkeyDidPress()
            }
        }
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
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
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
