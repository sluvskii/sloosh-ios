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

    static let accent = Color(red: 0.70, green: 1.0, blue: 0.0) // #B3FF00
}
