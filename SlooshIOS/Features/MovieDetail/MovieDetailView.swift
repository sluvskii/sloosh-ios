import SwiftUI
import AVKit

struct MovieDetailView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isPlayerPresented = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Image Placeholder
                ZStack(alignment: .bottomLeading) {
                    if let url = movie.posterURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .overlay {
                                        ProgressView()
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .overlay {
                                        Image(systemName: "film")
                                            .font(.largeTitle)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: 350)
                        .clipped()
                        .overlay {
                            LinearGradient(
                                colors: [.clear, SlooshTheme.background],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        }
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 350)
                            .overlay {
                                LinearGradient(
                                    colors: [.clear, SlooshTheme.background],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(movie.title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 12) {
                            Label(String(format: "%.1f", movie.rating), systemImage: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("•")
                            Text(movie.year)
                            Text("•")
                            Text(movie.type == "tv" ? "Сериал" : "Фильм")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button {
                            isPlayerPresented = true
                        } label: {
                            Label("Смотреть", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SlooshTheme.accent)
                        .foregroundStyle(.black)
                        
                        Button {
                            // Save action
                        } label: {
                            Image(systemName: "bookmark")
                                .font(.headline)
                                .padding(14)
                                .background(.ultraThinMaterial, in: Circle())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("О фильме")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Text(movie.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    
                    // Additional info in GlassCard
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(title: "Жанр", value: movie.genre)
                            Divider().background(Color.primary.opacity(0.1))
                            InfoRow(title: "Год выхода", value: movie.year)
                            Divider().background(Color.primary.opacity(0.1))
                            InfoRow(title: "Тип", value: movie.type == "tv" ? "Сериал" : "Фильм")
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .padding()
            }
        }
        .background(SlooshTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $isPlayerPresented) {
            PlayerView(movie: movie)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        MovieDetailView(movie: MockData.trendingMovies[0])
    }
}

struct PlayerView: View {
    let movie: Movie
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = AllohaPlayerViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                    Text("Загрузка видео...")
                        .foregroundStyle(.white)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text("Ошибка загрузки видео")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Повторить") {
                        Task {
                            await viewModel.loadVideo(for: movie)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(SlooshTheme.accent)
                    .foregroundStyle(.white)
                    .padding(.top, 8)
                    
                    Button("Закрыть") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SlooshTheme.accent)
                    .foregroundStyle(.black)
                    .padding(.top, 4)
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .task {
            await viewModel.loadVideo(for: movie)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}
