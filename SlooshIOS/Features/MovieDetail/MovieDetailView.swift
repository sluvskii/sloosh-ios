import SwiftUI
import AVKit

struct MovieDetailView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    @State private var isPlayerPresented = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top Action Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            // Bookmark action
                        } label: {
                            Image(systemName: "bookmark")
                                .font(.title3)
                                .foregroundStyle(.primary)
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        
                        ShareLink(item: URL(string: "https://sloosh.ru/movie/\(movie.id)")!) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .foregroundStyle(.primary)
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Poster
                if let url = movie.posterURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.secondary.opacity(0.2))
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
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
                    .frame(width: UIScreen.main.bounds.width * 0.65)
                    .aspectRatio(2/3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                }
                
                // Title
                Text(movie.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Play Button
                Button {
                    isPlayerPresented = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Смотреть")
                    }
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 32)
                    .background(SlooshTheme.accent, in: Capsule())
                }
                .padding(.top, 8)
                
                // Stats Row
                HStack(spacing: 0) {
                    StatItem(title: "КИНОПОИСК", value: String(format: "%.1f", movie.ratingValue), valueColor: SlooshTheme.accent)
                        .frame(maxWidth: .infinity)
                    
                    StatItem(title: "IMDb", value: String(format: "%.1f", movie.ratingValue), valueColor: SlooshTheme.accent) // TODO: map imdb rating if available
                        .frame(maxWidth: .infinity)
                    
                    StatItem(title: "Длительность", value: "—", valueColor: .primary)
                        .frame(maxWidth: .infinity)
                    
                    StatItem(title: "Возраст", value: "18+", valueColor: .primary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Info List
                VStack(alignment: .leading, spacing: 16) {
                    InfoTextRow(title: "Дата выхода:", value: movie.yearText)
                    InfoTextRow(title: "Страна:", value: "—")
                    InfoTextRow(title: "Жанр:", value: movie.genre)
                    InfoTextRow(title: "Режиссер:", value: "—")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Описание")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text(movie.descriptionText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
        }
        .background(SlooshTheme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $isPlayerPresented) {
            PlayerView(movie: movie)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(valueColor)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
}

struct InfoTextRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
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
