import SwiftUI
import AVKit

struct MovieDetailView: View {
    let movie: Movie
    @State private var isPlayerPresented = false
    @State private var isDescriptionExpanded = false
    @State private var isFavorite = false
    @State private var showCompactTitle = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                heroSection
                
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
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
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
        }
        .coordinateSpace(name: "detailScroll")
        .background(SlooshTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(showCompactTitle ? .visible : .hidden, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(1)
                    .opacity(showCompactTitle ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: showCompactTitle)
            }

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
        .onPreferenceChange(DetailTitleMinYPreferenceKey.self) { minY in
            let shouldShowCompactTitle = minY < 90
            guard shouldShowCompactTitle != showCompactTitle else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                showCompactTitle = shouldShowCompactTitle
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            heroBackground

            LinearGradient(
                colors: [
                    Color.black.opacity(0.05),
                    SlooshTheme.background.opacity(0.4),
                    SlooshTheme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 20) {
                Spacer(minLength: 100)

                posterSection
                    .frame(width: min(UIScreen.main.bounds.width * 0.5, 220))
                    .shadow(color: .black.opacity(0.28), radius: 24, y: 14)

                VStack(spacing: 10) {
                    Text(movie.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: DetailTitleMinYPreferenceKey.self,
                                    value: geometry.frame(in: .named("detailScroll")).minY
                                )
                            }
                        )

                    heroMetadata
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 28)
        }
        .frame(height: 540)
    }

    private var heroBackground: some View {
        Group {
            if let url = heroArtworkURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.secondary.opacity(0.18))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.secondary.opacity(0.18))
                    @unknown default:
                        Rectangle()
                            .fill(Color.secondary.opacity(0.18))
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.18))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .blur(radius: 32, opaque: true)
        .scaleEffect(1.08)
        .overlay {
            Rectangle()
                .fill(.black.opacity(0.12))
        }
    }

    private var heroMetadata: some View {
        HStack(spacing: 8) {
            if movie.ratingValue > 0 {
                Label(String(format: "%.1f", movie.ratingValue), systemImage: "star.fill")
                    .foregroundStyle(.yellow)
            }

            Text(movie.yearText)
            Text("\u{2022}")
            Text(movie.isSerial ? "Сериал" : "Фильм")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
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

    private var heroArtworkURL: URL? {
        movie.backdropURL ?? movie.posterURL
    }

    private var shareURL: URL {
        URL(string: "https://sloosh.ru/movie/\(movie.id)")!
    }
}

private struct DetailTitleMinYPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
