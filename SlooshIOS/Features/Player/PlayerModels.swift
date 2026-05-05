import Foundation

struct StreamResponse: Codable {
    let title: String
    let initialM3u8: String
    let initialSeason: Int
    let initialEpisode: Int
    let episodes: [StreamEpisode]
    let isSeries: Bool
    
    enum CodingKeys: String, CodingKey {
        case title
        case initialM3u8 = "initial_m3u8"
        case initialSeason = "initial_season"
        case initialEpisode = "initial_episode"
        case episodes
        case isSeries = "is_series"
    }
}

struct StreamEpisode: Codable, Identifiable, Hashable {
    let season: Int
    let episode: Int
    let title: String
    let filepath: String
    
    var id: String { "\(season)-\(episode)" }
}

struct Season: Identifiable, Hashable {
    let id: String
    let number: Int
    let episodes: [StreamEpisode]
}
