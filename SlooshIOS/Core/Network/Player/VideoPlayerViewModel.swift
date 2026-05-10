import Foundation
import AVFoundation
import Combine

@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var currentSource: VideoSource?
    @Published var availableEpisodes: [EpisodeInfo] = []
    @Published var currentSeason: Int = 1
    @Published var currentEpisode: Int = 1
    @Published var isSeries: Bool = false
    
    private let repository = SimplePlayerRepository()
    private var currentKpId: Int?
    private var cancellables = Set<AnyCancellable>()
    
    func setupNeoId(_ neoId: String) {
        repository.setNeoId(neoId)
    }
    
    func loadVideo(kpId: Int, season: Int? = nil, episode: Int? = nil) async {
        self.currentKpId = kpId
        self.isLoading = true
        self.errorMessage = nil
        self.player?.pause()
        self.player = nil
        
        do {
            let source = try await repository.getVideoSource(kpId: kpId, season: season, episode: episode)
            self.currentSource = source
            self.isSeries = source.isSeries
            self.availableEpisodes = source.episodes
            
            if let season = source.season, let episode = source.episode {
                self.currentSeason = season
                self.currentEpisode = episode
            }
            
            // Create player with direct URL
            guard let url = URL(string: source.url) else {
                throw PlayerError.invalidURL
            }
            
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            
            self.player = AVPlayer(playerItem: playerItem)
            self.isLoading = false
            
            // Start playing
            self.player?.play()
            
        } catch {
            self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func switchEpisode(season: Int, episode: Int) async {
        guard let kpId = currentKpId else { return }
        await loadVideo(kpId: kpId, season: season, episode: episode)
    }
    
    func cleanup() {
        player?.pause()
        player = nil
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func seek(to time: CMTime) {
        player?.seek(to: time)
    }
}

// MARK: - Supporting Types

struct VideoSource {
    let url: String
    let type: VideoSourceType
    let title: String
    let season: Int?
    let episode: Int?
    let isSeries: Bool
    let episodes: [EpisodeInfo]
}

enum VideoSourceType {
    case cdn
    case alloha
    case collaps
    case hdvb
    case lumex
    case vibix
}

struct EpisodeInfo: Identifiable {
    let id = UUID()
    let season: Int
    let episode: Int
    let title: String
    let m3u8Url: String
    let translation: String?
}

enum PlayerError: Error, LocalizedError {
    case noAvailableSource
    case cdnResolutionFailed
    case cdnIdNotFound
    case contentInfoFailed
    case episodesFailed
    case episodeNotFound
    case noVideoSource
    case balancerFailed
    case invalidResponse
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .noAvailableSource:
            return "Нет доступного источника видео"
        case .cdnResolutionFailed:
            return "Ошибка резолва CDN"
        case .cdnIdNotFound:
            return "CDN ID не найден"
        case .contentInfoFailed:
            return "Ошибка получения информации о контенте"
        case .episodesFailed:
            return "Ошибка получения списка эпизодов"
        case .episodeNotFound:
            return "Эпизод не найден"
        case .noVideoSource:
            return "Источник видео не найден"
        case .balancerFailed:
            return "Ошибка балансера"
        case .invalidResponse:
            return "Некорректный ответ сервера"
        case .invalidURL:
            return "Некорректный URL"
        }
    }
}
