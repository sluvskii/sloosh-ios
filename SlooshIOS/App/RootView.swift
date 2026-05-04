import SwiftUI
import UIKit

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
            
            SearchView()
                .tabItem {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
            
            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
        }
        .tint(SlooshTheme.accent)
        .onAppear {
            // Customize TabBar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            // appearance.backgroundColor = ... (uses default adaptive)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootView()
        // .preferredColorScheme(.dark)
}
