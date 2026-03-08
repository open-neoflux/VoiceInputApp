import Foundation
import AppKit

class ClipboardService {
    static let shared = ClipboardService()

    private let pasteboard = NSPasteboard.general

    private init() {}

    func copyToClipboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func getFromClipboard() -> String? {
        return pasteboard.string(forType: .string)
    }

    func clearClipboard() {
        pasteboard.clearContents()
    }

    func hasText() -> Bool {
        return pasteboard.string(forType: .string) != nil
    }
}