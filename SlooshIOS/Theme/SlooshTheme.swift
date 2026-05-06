import SwiftUI

enum SlooshTheme {
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    
    // Dynamic color directly in code
    static let accent = Color(UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor(red: 0.70, green: 1.0, blue: 0.0, alpha: 1.0) // #B3FF00 for Dark
        } else {
            return UIColor(red: 0.45, green: 0.80, blue: 0.0, alpha: 1.0) // Darker green for Light
        }
    })
}
