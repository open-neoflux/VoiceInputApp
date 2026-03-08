import Foundation

enum Constants {
    // App Info
    static let appName = "VoiceInputApp"
    static let appVersion = "1.0.0"

    // Default Settings
    static let defaultHotkeyModifiers: UInt = UInt(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue)
    static let defaultHotkeyKeyCode: UInt16 = 49 // Space

    // UI
    static let popoverWidth: CGFloat = 280
    static let popoverHeight: CGFloat = 200

    // Timing
    static let recordingTimeout: TimeInterval = 60.0
    static let processingDelay: TimeInterval = 0.5
}

import AppKit

extension NSEvent.ModifierFlags {
    var displayName: String {
        var parts: [String] = []

        if contains(.command) { parts.append("⌘") }
        if contains(.option) { parts.append("⌥") }
        if contains(.control) { parts.append("⌃") }
        if contains(.shift) { parts.append("⇧") }

        return parts.joined()
    }
}