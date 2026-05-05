import SwiftUI

struct Movie: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let description: String
    let rating: Double
    let year: String
    let genre: String
    let duration: String
    let posterPath: String?
    let type: String?
    
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        
        if posterPath.hasPrefix("http") {
            return URL(string: posterPath)
        }
        
        // По документации NeoMovies API, картинки раздаются через их прокси
        let baseURL = "https://api.neomovies.ru"
        return URL(string: baseURL + posterPath)
    }
    
    // Структура жанра из NeoMovies API
    struct Genre: Codable, Hashable {
        let id: String?
        let name: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case originalTitle
        case description
        case rating
        case year
        case posterUrl
        case genres
        case type
    }
    
    init(id: String = UUID().uuidString, title: String, description: String, rating: Double, year: String, genre: String, duration: String, posterPath: String? = nil, type: String? = "movie") {
        self.id = id
        self.title = title
        self.description = description
        self.rating = rating
        self.year = year
        self.genre = genre
        self.duration = duration
        self.posterPath = posterPath
        self.type = type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        
        if let title = try? container.decode(String.self, forKey: .title) {
            self.title = title
        } else if let originalTitle = try? container.decode(String.self, forKey: .originalTitle) {
            self.title = originalTitle
        } else {
            self.title = "Unknown"
        }
        
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? "Описание отсутствует"
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0.0
        
        if let yearInt = try? container.decodeIfPresent(Int.self, forKey: .year) {
            self.year = String(yearInt)
        } else if let yearString = try? container.decodeIfPresent(String.self, forKey: .year) {
            self.year = yearString
        } else {
            self.year = ""
        }
        
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterUrl)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        
        if let genres = try? container.decodeIfPresent([Genre].self, forKey: .genres), !genres.isEmpty {
            self.genre = genres.prefix(2).map { $0.name.capitalized }.joined(separator: ", ")
        } else {
            self.genre = self.type == "tv" ? "Сериал" : "Фильм"
        }
        
        self.duration = self.type == "tv" ? "Сериал" : "Фильм"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(rating, forKey: .rating)
        
        if let yearInt = Int(year) {
            try container.encode(yearInt, forKey: .year)
        }
        
        try container.encode(posterPath, forKey: .posterUrl)
        try container.encode(type, forKey: .type)
        
        let singleGenre = Genre(id: nil, name: genre)
        try container.encode([singleGenre], forKey: .genres)
    }
}
