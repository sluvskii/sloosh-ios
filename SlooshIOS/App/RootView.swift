import SwiftUI

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
            appearance.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.1, alpha: 0.95)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
