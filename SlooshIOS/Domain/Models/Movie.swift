import Foundation

struct Movie: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let originalTitle: String?
    let year: Int?
    let rating: Double?
    let posterUrl: String?
    let backdropUrl: String?
    let description: String?
    let type: String?
    let genres: [Genre]?
    let externalIds: ExternalIds?

    struct Genre: Codable, Hashable {
        let id: String?
        let name: String?
    }

    struct ExternalIds: Codable, Hashable {
        let kp: Int?
        let tmdb: Int?
        let imdb: String?
    }

    init(
        id: String,
        title: String,
        originalTitle: String? = nil,
        year: Int? = nil,
        rating: Double? = nil,
        posterUrl: String? = nil,
        backdropUrl: String? = nil,
        description: String? = nil,
        type: String? = nil,
        genres: [Genre]? = nil,
        externalIds: ExternalIds? = nil
    ) {
        self.id = id
        self.title = title
        self.originalTitle = originalTitle
        self.year = year
        self.rating = rating
        self.posterUrl = posterUrl
        self.backdropUrl = backdropUrl
        self.description = description
        self.type = type
        self.genres = genres
        self.externalIds = externalIds
    }

    var fullPosterUrl: String? {
        guard let path = posterUrl else { return nil }
        if path.hasPrefix("http") { return path }
        return "https://api.neomovies.ru" + path
    }

    var fullBackdropUrl: String? {
        guard let path = backdropUrl else { return nil }
        if path.hasPrefix("http") { return path }
        return "https://api.neomovies.ru" + path
    }

    var kpId: Int? {
        let clean = id.replacingOccurrences(of: "kp_", with: "")
        return Int(clean)
    }

    var isSerial: Bool {
        type == "tv"
    }

    // Compatibility helpers for existing SwiftUI views.
    var posterURL: URL? {
        guard let fullPosterUrl else { return nil }
        return URL(string: fullPosterUrl)
    }

    var backdropURL: URL? {
        guard let fullBackdropUrl else { return nil }
        return URL(string: fullBackdropUrl)
    }

    var genre: String {
        let names = (genres ?? [])
            .compactMap(\.name)
            .prefix(2)

        if names.isEmpty {
            return isSerial ? "Сериал" : "Фильм"
        }

        return names.joined(separator: ", ")
    }

    var yearText: String {
        guard let year else { return "Неизвестно" }
        return String(year)
    }

    var ratingValue: Double {
        rating ?? 0
    }

    var descriptionText: String {
        let trimmed = description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Описание отсутствует" : trimmed
    }
}
