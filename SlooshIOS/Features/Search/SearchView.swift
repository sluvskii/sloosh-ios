import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                SlooshTheme.background.ignoresSafeArea()
                
                VStack {
                    if viewModel.searchText.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(.tertiary)
                            Text("Поиск фильмов и сериалов")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else if viewModel.isLoading {
                        ProgressView()
                            .frame(maxHeight: .infinity)
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(.tertiary)
                            Text(errorMessage)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(viewModel.movies) { movie in
                                    NavigationLink(value: movie) {
                                        MovieCardView(movie: movie)
                                            .onAppear {
                                                Task {
                                                    await viewModel.loadMoreIfNeeded(currentMovie: movie)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                            
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Поиск")
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Название фильма...")
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.performSearch()
        }
    }
}

#Preview {
    SearchView()
}
