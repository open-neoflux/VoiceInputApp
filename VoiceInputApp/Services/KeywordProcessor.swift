import Foundation

class KeywordProcessor {
    private var keywordActions: [KeywordAction]

    init(keywordActions: [KeywordAction] = KeywordAction.defaultActions) {
        self.keywordActions = keywordActions
    }

    func updateKeywordActions(_ actions: [KeywordAction]) {
        self.keywordActions = actions
    }

    /// Process text and extract keyword actions
    /// Returns tuple of (remaining text, actions to perform)
    func processText(_ text: String) -> (String, [KeyboardAction]) {
        var remainingText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var actions: [KeyboardAction] = []

        for keywordAction in keywordActions {
            let keyword = keywordAction.keyword.lowercased()

            // Check if keyword exists in text (case insensitive)
            if remainingText.lowercased().contains(keyword) {
                // Remove keyword from text
                if let range = remainingText.range(of: keyword, options: .caseInsensitive) {
                    remainingText.removeSubrange(range)
                }
                remainingText = remainingText.trimmingCharacters(in: .whitespacesAndNewlines)

                // Add action to perform
                actions.append(keywordAction.action)
            }
        }

        return (remainingText, actions)
    }

    /// Check if text contains any keyword
    func containsKeyword(_ text: String) -> Bool {
        for keywordAction in keywordActions {
            if text.lowercased().contains(keywordAction.keyword.lowercased()) {
                return true
            }
        }
        return false
    }

    /// Get action for a specific keyword
    func getAction(forKeyword keyword: String) -> KeyboardAction? {
        return keywordActions.first { $0.keyword.lowercased() == keyword.lowercased() }?.action
    }

    /// Get all keywords
    var allKeywords: [String] {
        return keywordActions.map { $0.keyword }
    }
}