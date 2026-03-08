import Foundation
import AppKit
import Carbon

class KeyboardService {
    static let shared = KeyboardService()

    private init() {}

    func pressKey(keyCode: CGKeyCode, modifiers: CGEventFlags = []) {
        let source = CGEventSource(stateID: .combinedSessionState)

        // Create key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: source,
                                          virtualKey: keyCode,
                                          keyDown: true) else { return }
        keyDownEvent.flags = modifiers
        keyDownEvent.post(tap: .cghidEventTap)

        // Create key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: source,
                                        virtualKey: keyCode,
                                        keyDown: false) else { return }
        keyUpEvent.flags = modifiers
        keyUpEvent.post(tap: .cghidEventTap)
    }

    func pressKeyWithModifiers(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        pressKey(keyCode: keyCode, modifiers: modifiers)
    }

    func typeText(_ text: String) {
        let source = CGEventSource(stateID: .combinedSessionState)

        for scalar in text.unicodeScalars {
            guard let event = CGEvent(keyboardEventSource: source,
                                       virtualKey: 0,
                                       keyDown: true) else { continue }
            var char = UniChar(scalar.value)
            event.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
            event.post(tap: .cghidEventTap)

            if let eventUp = event.copy() as CGEvent? {
                eventUp.type = .keyUp
                eventUp.post(tap: .cghidEventTap)
            }
        }
    }

    func performAction(_ action: KeyboardAction) {
        pressKey(keyCode: action.keyCode)
    }

    // MARK: - Convenience Methods

    func pressEnter() {
        pressKey(keyCode: CGKeyCode(kVK_Return))
    }

    func pressTab() {
        pressKey(keyCode: CGKeyCode(kVK_Tab))
    }

    func pressEscape() {
        pressKey(keyCode: CGKeyCode(kVK_Escape))
    }

    func pressBackspace() {
        pressKey(keyCode: CGKeyCode(kVK_Delete))
    }

    func pressSpace() {
        pressKey(keyCode: CGKeyCode(kVK_Space))
    }

    func pressArrowKey(_ direction: ArrowDirection) {
        let keyCode: CGKeyCode
        switch direction {
        case .up: keyCode = CGKeyCode(kVK_UpArrow)
        case .down: keyCode = CGKeyCode(kVK_DownArrow)
        case .left: keyCode = CGKeyCode(kVK_LeftArrow)
        case .right: keyCode = CGKeyCode(kVK_RightArrow)
        }
        pressKey(keyCode: keyCode)
    }
}

enum ArrowDirection {
    case up, down, left, right
}