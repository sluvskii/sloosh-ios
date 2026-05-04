import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                SlooshTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        Circle()
                            .fill(SlooshTheme.accent.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(SlooshTheme.accent)
                            }
                            .padding(.top, 32)
                        
                        Text("Киноман")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        
                        GlassCard {
                            VStack(spacing: 0) {
                                NavigationLink {
                                    Text("Избранное")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(SlooshTheme.background.ignoresSafeArea())
                                } label: {
                                    SettingsRow(icon: "heart.fill", title: "Избранное")
                                }
                                
                                Divider().background(.white.opacity(0.2)).padding(.vertical, 12)
                                
                                NavigationLink {
                                    Text("Настройки")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(SlooshTheme.background.ignoresSafeArea())
                                } label: {
                                    SettingsRow(icon: "gearshape.fill", title: "Настройки")
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Профиль")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(SlooshTheme.accent)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundStyle(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.3))
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    ProfileView()
}
