import Foundation

public struct StreamResponse: Codable {
    public let title: String
    public let initialM3u8: String
    public let initialSeason: Int
    public let initialEpisode: Int
    public let episodes: [StreamEpisode]
    public let isSeries: Bool
    
    enum CodingKeys: String, CodingKey {
        case title
        case initialM3u8 = "initial_m3u8"
        case initialSeason = "initial_season"
        case initialEpisode = "initial_episode"
        case episodes
        case isSeries = "is_series"
    }
}

public struct StreamEpisode: Codable, Identifiable, Hashable {
    public let season: Int
    public let episode: Int
    public let title: String
    public let filepath: String
    
    public var id: String { "\(season)-\(episode)" }
}

public struct Season: Identifiable, Hashable {
    public let id: String
    public let number: Int
    public let episodes: [StreamEpisode]
}
