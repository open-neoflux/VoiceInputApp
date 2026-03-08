import Foundation
import Carbon

enum KeyboardAction: String, Codable, CaseIterable {
    case enter = "回车键"
    case arrowUp = "上键"
    case arrowDown = "下键"
    case arrowLeft = "左键"
    case arrowRight = "右键"
    case tab = "Tab键"
    case escape = "Esc键"
    case backspace = "删除键"
    case space = "空格键"

    var keyCode: CGKeyCode {
        switch self {
        case .enter: return CGKeyCode(kVK_Return)
        case .arrowUp: return CGKeyCode(kVK_UpArrow)
        case .arrowDown: return CGKeyCode(kVK_DownArrow)
        case .arrowLeft: return CGKeyCode(kVK_LeftArrow)
        case .arrowRight: return CGKeyCode(kVK_RightArrow)
        case .tab: return CGKeyCode(kVK_Tab)
        case .escape: return CGKeyCode(kVK_Escape)
        case .backspace: return CGKeyCode(kVK_Delete)
        case .space: return CGKeyCode(kVK_Space)
        }
    }

    var displayName: String {
        return rawValue
    }

    var icon: String {
        switch self {
        case .enter: return "return"
        case .arrowUp: return "arrow.up"
        case .arrowDown: return "arrow.down"
        case .arrowLeft: return "arrow.left"
        case .arrowRight: return "arrow.right"
        case .tab: return "arrow.right.to.line"
        case .escape: return "escape"
        case .backspace: return "delete.left"
        case .space: return "space"
        }
    }

    // 从 keyCode 获取对应的 KeyboardAction
    static func from(keyCode: CGKeyCode) -> KeyboardAction? {
        switch Int(keyCode) {
        case kVK_Return: return .enter
        case kVK_UpArrow: return .arrowUp
        case kVK_DownArrow: return .arrowDown
        case kVK_LeftArrow: return .arrowLeft
        case kVK_RightArrow: return .arrowRight
        case kVK_Tab: return .tab
        case kVK_Escape: return .escape
        case kVK_Delete: return .backspace
        case kVK_Space: return .space
        default: return nil
        }
    }
}

struct KeywordAction: Identifiable, Codable {
    var id = UUID()
    var keyword: String
    var action: KeyboardAction

    init(keyword: String, action: KeyboardAction) {
        self.keyword = keyword
        self.action = action
    }

    static var defaultActions: [KeywordAction] {
        return [
            KeywordAction(keyword: "结束", action: .enter),
            KeywordAction(keyword: "上移", action: .arrowUp),
            KeywordAction(keyword: "下移", action: .arrowDown),
            KeywordAction(keyword: "左移", action: .arrowLeft),
            KeywordAction(keyword: "右移", action: .arrowRight)
        ]
    }
}