import SwiftUI
import AVKit

struct PlayerSelectionView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    
    @State private var streamData: StreamResponse?
    @State private var selectedSeason: Int?
    @State private var isPlaying = false
    @State private var currentURLToPlay: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Группируем серии по сезонам
    private var seasons: [Season] {
        guard let data = streamData else { return [] }
        
        let grouped = Dictionary(grouping: data.episodes, by: { $0.season })
        return grouped.map { Season(id: "\($0.key)", number: $0.key, episodes: $0.value.sorted(by: { $0.episode < $1.episode })) }
            .sorted(by: { $0.number < $1.number })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SlooshTheme.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Загрузка плеера...")
                        .tint(SlooshTheme.accent)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text("Ошибка загрузки видео")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Повторить") {
                            Task {
                                await loadData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SlooshTheme.accent)
                        .foregroundStyle(.black)
                    }
                    .padding()
                } else if let data = streamData {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(movie.title)
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(.primary)
                                
                                Text(data.isSeries ? "Выберите серию для просмотра" : "Приятного просмотра")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            
                            if data.isSeries {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Сезон")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal)
                                    
                                    Picker("Сезон", selection: $selectedSeason) {
                                        ForEach(seasons) { season in
                                            Text("Сезон \(season.number)").tag(Optional(season.number))
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .padding(.horizontal)
                                    
                                    if let currentSeasonNum = selectedSeason, let season = seasons.first(where: { $0.number == currentSeasonNum }) {
                                        VStack(spacing: 8) {
                                            ForEach(season.episodes) { episode in
                                                Button {
                                                    play(url: episode.filepath)
                                                } label: {
                                                    HStack {
                                                        Text("\(episode.episode). \(episode.title)")
                                                            .foregroundStyle(.primary)
                                                            .multilineTextAlignment(.leading)
                                                        Spacer()
                                                        Image(systemName: "play.circle.fill")
                                                            .foregroundStyle(SlooshTheme.accent)
                                                    }
                                                    .padding()
                                                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            } else {
                                // Фильм
                                Button {
                                    play(url: data.initialM3u8)
                                } label: {
                                    Label("Включить фильм", systemImage: "play.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(SlooshTheme.accent)
                                .foregroundStyle(.black)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Смотреть")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .tint(.primary)
                }
            }
            .task {
                await loadData()
            }
            .fullScreenCover(isPresented: $isPlaying) {
                if let url = currentURLToPlay {
                    NativePlayerView(url: url)
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    private func loadData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let data = try await NeoMoviesService.shared.fetchStream(kpId: movie.id)
            await MainActor.run {
                streamData = data
                if data.isSeries {
                    selectedSeason = data.initialSeason
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func play(url: String) {
        if let parsedURL = URL(string: url) {
            currentURLToPlay = parsedURL
            isPlaying = true
        } else {
            errorMessage = "Неверная ссылка на видео"
        }
    }
}

// Обертка над AVPlayerViewController для красивого системного UI
struct NativePlayerView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        
        // Позволяем плееру самому выбирать лучшую аудиодорожку и субтитры
        player.appliesMediaSelectionCriteriaAutomatically = true
        
        controller.player = player
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = true
        
        // Автоматически запускаем видео
        player.play()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Обновлять нечего
    }
}
