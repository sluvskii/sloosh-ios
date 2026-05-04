import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            SlooshTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Sloosh")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Стартовая iOS-база готова. Дальше можно переносить домашний экран, детали фильма и поиск поэтапно.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.72))

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("SwiftUI + NavigationStack", systemImage: "iphone.gen3")
                            Label("Системные материалы вместо самописного glass", systemImage: "drop")
                            Label("Минимальный iOS target: 18.0", systemImage: "hammer")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                    }

                    NavigationLink {
                        Text("Следующим шагом тут можно открыть экран деталей фильма.")
                            .padding()
                            .navigationTitle("Детали")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .background(SlooshTheme.background.ignoresSafeArea())
                    } label: {
                        Text("Открыть пример навигации")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SlooshTheme.accent)
                }
                .padding(20)
            }
        }
        .navigationTitle("Главная")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
