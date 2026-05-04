import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                SlooshTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // Trending Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("В тренде")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(MockData.trendingMovies) { movie in
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
                                    ForEach(MockData.newSeries) { movie in
                                        NavigationLink(value: movie) {
                                            MovieCardView(movie: movie)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("sloosh")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
        }
    }
}

#Preview {
    HomeView()
}
