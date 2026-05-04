import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                SlooshTheme.background.ignoresSafeArea()
                
                VStack {
                    if searchText.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.3))
                            Text("Поиск фильмов и сериалов")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    } else {
                        // Here will be search results
                        Spacer()
                    }
                }
            }
            .navigationTitle("Поиск")
        }
        .searchable(text: $searchText, prompt: "Название фильма...")
    }
}

#Preview {
    SearchView()
}
