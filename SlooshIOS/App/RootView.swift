import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
        .tint(SlooshTheme.accent)
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
