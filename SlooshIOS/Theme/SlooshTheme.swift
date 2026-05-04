import SwiftUI

enum SlooshTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.03, green: 0.04, blue: 0.08),
            Color(red: 0.08, green: 0.10, blue: 0.18),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = Color(red: 0.47, green: 0.78, blue: 1.0)
}
