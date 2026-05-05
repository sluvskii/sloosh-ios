import SwiftUI

struct Movie: Identifiable, Hashable, Codable {
    let id: Int
    let title: String
    let description: String
    let rating: Double
    let year: String
    let genre: String
    let duration: String
    let posterPath: String?
    
    var posterColor: Color {
        let colors: [Color] = [.red, .blue, .green, .purple, .orange, .pink, .teal, .indigo]
        return colors[abs(id) % colors.count]
    }
    
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case description = "overview"
        case rating = "vote_average"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case posterPath = "poster_path"
    }
    
    init(id: Int = Int.random(in: 1...1000000), title: String, description: String, rating: Double, year: String, genre: String, duration: String, posterPath: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.rating = rating
        self.year = year
        self.genre = genre
        self.duration = duration
        self.posterPath = posterPath
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        
        if let title = try? container.decode(String.self, forKey: .title) {
            self.title = title
        } else if let name = try? container.decode(String.self, forKey: .name) {
            self.title = name
        } else {
            self.title = "Unknown"
        }
        
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0.0
        
        let dateString = (try? container.decode(String.self, forKey: .releaseDate)) ?? (try? container.decode(String.self, forKey: .firstAirDate)) ?? ""
        self.year = String(dateString.prefix(4))
        
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        
        self.genre = container.contains(.name) ? "Сериал" : "Фильм"
        self.duration = container.contains(.name) ? "1 Сезон" : "2ч 0м"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(rating, forKey: .rating)
        try container.encode(year, forKey: .releaseDate)
        try container.encode(posterPath, forKey: .posterPath)
    }
}
