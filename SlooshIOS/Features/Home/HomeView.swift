import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                SlooshTheme.background
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                        
                        Button("Повторить") {
                            Task {
                                await viewModel.loadInitial()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
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
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("sloosh")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
        }
        .task {
            await viewModel.loadInitial()
        }
    }
}

#Preview {
    HomeView()
}
