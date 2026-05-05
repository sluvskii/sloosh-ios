import SwiftUI

struct HomeView: View {
    @State private var trendingMovies: [Movie] = []
    @State private var newSeries: [Movie] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                SlooshTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        if isLoading && trendingMovies.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 50)
                        } else if let errorMessage = errorMessage, trendingMovies.isEmpty {
                            VStack(spacing: 16) {
                                Text(errorMessage)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                                
                                Button("Повторить") {
                                    Task {
                                        await loadData()
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 50)
                        } else {
                            // Trending Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("В тренде")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(trendingMovies) { movie in
                                            NavigationLink(value: movie) {
                                                MovieCardView(movie: movie)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // New Series Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Новые сериалы")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(newSeries) { movie in
                                            NavigationLink(value: movie) {
                                                MovieCardView(movie: movie)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
                .refreshable {
                    await loadData()
                }
            }
            .navigationTitle("sloosh")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
        }
        .task {
            if trendingMovies.isEmpty {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchTrending = NeoMoviesService.shared.getPopular()
            async let fetchSeries = NeoMoviesService.shared.getTopTv()
            
            let (trending, series) = try await (fetchTrending, fetchSeries)
            
            // В SwiftUI начиная с iOS 15 свойства @State можно обновлять из async контекста,
            // но для надежности обернем в MainActor (или можно просто использовать await MainActor.run)
            await MainActor.run {
                self.trendingMovies = trending
                self.newSeries = series
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Не удалось загрузить фильмы.\nПроверьте подключение к сети."
                self.isLoading = false
            }
        }
    }
}

#Preview {
    HomeView()
}
