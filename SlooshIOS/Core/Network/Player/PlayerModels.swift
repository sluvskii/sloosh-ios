import Foundation

// MARK: - CDN API Models

struct CDNContentInfo: Codable {
    let id: UInt64
    let title: String
    let hasMultipleEpisodes: Bool
    let trailerUrls: [String]?
}

struct CDNEpisode: Codable {
    let id: UInt64
    let title: String
    let order: UInt32
    let season: CDNEpisodeSeason
    let episodeVariants: [CDNEpisodeVariant]
}

struct CDNEpisodeSeason: Codable {
    let id: UInt64
    let order: UInt32
}

struct CDNEpisodeVariant: Codable {
    let filepath: String
}

struct CDNEpisodeJs: Codable {
    let season: UInt32
    let episode: UInt32
    let title: String
    let filepath: String
}

struct PlayerData: Codable {
    let title: String
    let initialM3u8: String
    let initialSeason: UInt32
    let initialEpisode: UInt32
    let episodes: [CDNEpisodeJs]
    let isSeries: Bool
    let cdnId: UInt64
}

// MARK: - Balancer Response Models

struct BalancerVideo: Codable {
    let id: String
    let url: String
    let quality: String?
    let translation: String?
}

struct BalancerSeason: Codable {
    let number: Int
    let episodes: [BalancerEpisode]
}

struct BalancerEpisode: Codable {
    let number: Int
    let title: String?
    let videos: [BalancerVideo]
}

struct BalancerResponse: Codable {
    let success: Bool
    let error: String?
    let data: BalancerData?
}

struct BalancerData: Codable {
    let videos: [BalancerVideo]?
    let seasons: [BalancerSeason]?
    let translations: [Translation]?
}

struct Translation: Codable {
    let id: String
    let name: String
    let defaultQuality: String?
}

// MARK: - Player State

enum PlayerState {
    case idle
    case loading
    case ready
    case playing
    case paused
    case buffering
    case error(String)
}

enum BalancerType: String, CaseIterable {
    case cdn = "CDN"
    case alloha = "Alloha"
    case collaps = "Collaps"
    case hdvb = "HDVB"
    case lumex = "Lumex"
    case vibix = "Vibix"
}

// MARK: - Episode Info

struct EpisodeInfo: Identifiable {
    let id = UUID()
    let season: Int
    let episode: Int
    let title: String
    let m3u8Url: String
    let translation: String?
}

// MARK: - Video Quality

enum VideoQuality: String, CaseIterable {
    case auto = "auto"
    case p1080 = "1080p"
    case p720 = "720p"
    case p480 = "480p"
    case p360 = "360p"
}
