import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var keywordActions: [KeywordAction] {
        didSet {
            saveKeywordActions()
        }
    }

    @Published var triggerKeys: [String] {
        didSet {
            saveTriggerKeys()
        }
    }

    @Published var autoCopyToClipboard: Bool {
        didSet {
            UserDefaults.standard.set(autoCopyToClipboard, forKey: Keys.autoCopyToClipboard)
        }
    }

    @Published var showNotification: Bool {
        didSet {
            UserDefaults.standard.set(showNotification, forKey: Keys.showNotification)
        }
    }

    private enum Keys {
        static let keywordActions = "keywordActions"
        static let triggerKeys = "triggerKeys"
        static let autoCopyToClipboard = "autoCopyToClipboard"
        static let showNotification = "showNotification"
    }

    private init() {
        // Load saved settings
        if let data = UserDefaults.standard.data(forKey: Keys.keywordActions),
           let decoded = try? JSONDecoder().decode([KeywordAction].self, from: data) {
            self.keywordActions = decoded
        } else {
            self.keywordActions = KeywordAction.defaultActions
        }

        // Load trigger keys
        if let savedKeys = UserDefaults.standard.stringArray(forKey: Keys.triggerKeys), !savedKeys.isEmpty {
            self.triggerKeys = savedKeys
        } else {
            self.triggerKeys = ["FN"]  // Default to FN key
        }

        self.autoCopyToClipboard = UserDefaults.standard.bool(forKey: Keys.autoCopyToClipboard)
        if !UserDefaults.standard.bool(forKey: Keys.autoCopyToClipboard + "_initialized") {
            self.autoCopyToClipboard = true
            UserDefaults.standard.set(true, forKey: Keys.autoCopyToClipboard + "_initialized")
        }

        self.showNotification = UserDefaults.standard.bool(forKey: Keys.showNotification)
        if !UserDefaults.standard.bool(forKey: Keys.showNotification + "_initialized") {
            self.showNotification = true
            UserDefaults.standard.set(true, forKey: Keys.showNotification + "_initialized")
        }
    }

    private func saveKeywordActions() {
        if let encoded = try? JSONEncoder().encode(keywordActions) {
            UserDefaults.standard.set(encoded, forKey: Keys.keywordActions)
        }
    }

    private func saveTriggerKeys() {
        UserDefaults.standard.set(triggerKeys, forKey: Keys.triggerKeys)
    }

    func resetToDefaults() {
        keywordActions = KeywordAction.defaultActions
        triggerKeys = ["FN"]
        autoCopyToClipboard = true
        showNotification = true
    }
}