import SwiftUI
import AVKit

struct MovieDetailView: View {
    let movie: Movie
    @State private var isPlayerPresented = false
    @State private var isDescriptionExpanded = false
    @State private var isFavorite = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Poster
                posterSection
                
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
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(SlooshTheme.accent, in: Capsule())
                }
                .padding(.horizontal, 24)
                
                // Stats Row
                HStack(spacing: 12) {
                    StatCard(title: "Кинопоиск", value: String(format: "%.1f", movie.ratingValue), color: SlooshTheme.accent)
                    StatCard(title: "IMDb", value: "—", color: SlooshTheme.accent) // TODO: map imdb rating
                    StatCard(title: "Время", value: "—", color: .primary)
                    StatCard(title: "Возраст", value: "18+", color: .primary)
                }
                .padding(.horizontal)
                
                // Info List
                VStack(spacing: 12) {
                    InfoRowView(title: "Дата выхода", value: movie.yearText)
                    InfoRowView(title: "Страна", value: "—")
                    InfoRowView(title: "Жанр", value: movie.genre)
                    InfoRowView(title: "Режиссер", value: "—")
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal)
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Описание")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text(movie.descriptionText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(6)
                        .lineLimit(isDescriptionExpanded ? nil : 4)
                        .animation(.easeInOut, value: isDescriptionExpanded)
                    
                    if movie.descriptionText.count > 100 {
                        Button {
                            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                                isDescriptionExpanded.toggle()
                            }
                        } label: {
                            Text(isDescriptionExpanded ? "Скрыть" : "Показать полностью")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SlooshTheme.accent)
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.top, 24)
            .background(alignment: .top) {
                if let url = movie.posterURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: UIScreen.main.bounds.width, height: 600)
                                .clipped()
                                .blur(radius: 40, opaque: true)
                                .overlay {
                                    LinearGradient(
                                        colors: [SlooshTheme.background.opacity(0.2), SlooshTheme.background],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                        }
                    }
                    .padding(.top, -150)
                }
            }
        }
        .background(SlooshTheme.background.ignoresSafeArea())
        .navigationTitle(movie.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackgroundVisibility(.automatic, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isFavorite.toggle()
                } label: {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                }

                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .fullScreenCover(isPresented: $isPlayerPresented) {
            PlayerView(movie: movie)
        }
    }

    private var posterSection: some View {
        ZStack {
            if let url = movie.posterURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(0.2))
                            .overlay { ProgressView() }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
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
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.secondary.opacity(0.2))
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.5)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        }
    }

    private var shareURL: URL {
        URL(string: "https://sloosh.ru/movie/\(movie.id)")!
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct InfoRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
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
