import SwiftUI

@main
struct SlooshIOSApp: App {
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appTheme.colorScheme)
        }
    }
}
