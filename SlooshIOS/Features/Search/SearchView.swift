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
                                .foregroundStyle(.tertiary)
                            Text("Поиск фильмов и сериалов")
                                .font(.headline)
                                .foregroundStyle(.secondary)
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
