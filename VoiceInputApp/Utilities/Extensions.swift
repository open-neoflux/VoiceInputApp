import Foundation
import SwiftUI

extension Color {
    static let appAccent = Color.blue
    static let recordingRed = Color.red.opacity(0.8)
    static let idleGray = Color.gray.opacity(0.5)
}

extension View {
    func roundedCard(padding: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
    }
}

extension String {
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func containsCaseInsensitive(_ other: String) -> Bool {
        return self.lowercased().contains(other.lowercased())
    }
}