import Foundation
import SwiftUI
import Combine
import Carbon

class SettingsViewModel: ObservableObject {
    @Published var keywordActions: [KeywordAction]
    @Published var autoCopyToClipboard: Bool
    @Published var showNotification: Bool
    @Published var triggerKeys: [String]

    private let settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.keywordActions = settings.keywordActions
        self.autoCopyToClipboard = settings.autoCopyToClipboard
        self.showNotification = settings.showNotification
        self.triggerKeys = settings.triggerKeys

        setupBindings()
    }

    private func setupBindings() {
        $keywordActions
            .sink { [weak self] actions in
                self?.settings.keywordActions = actions
            }
            .store(in: &cancellables)

        $autoCopyToClipboard
            .sink { [weak self] value in
                self?.settings.autoCopyToClipboard = value
            }
            .store(in: &cancellables)

        $showNotification
            .sink { [weak self] value in
                self?.settings.showNotification = value
            }
            .store(in: &cancellables)

        $triggerKeys
            .sink { [weak self] keys in
                self?.settings.triggerKeys = keys
            }
            .store(in: &cancellables)
    }

    func addKeywordAction(keyword: String, action: KeyboardAction) {
        let newAction = KeywordAction(keyword: keyword, action: action)
        keywordActions.append(newAction)
    }

    func removeKeywordAction(at index: Int) {
        if index >= 0 && index < keywordActions.count {
            keywordActions.remove(at: index)
        }
    }

    func updateKeywordAction(at index: Int, keyword: String, action: KeyboardAction) {
        if index >= 0 && index < keywordActions.count {
            keywordActions[index].keyword = keyword
            keywordActions[index].action = action
        }
    }

    func resetToDefaults() {
        settings.resetToDefaults()
        keywordActions = settings.keywordActions
        autoCopyToClipboard = settings.autoCopyToClipboard
        showNotification = settings.showNotification
        triggerKeys = settings.triggerKeys
    }
}