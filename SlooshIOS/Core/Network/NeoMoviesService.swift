import Foundation

struct NeoEnvelope<T: Codable>: Codable {
    let success: Bool
    let data: T
}

struct NeoMediaResponse: Codable {
    let results: [Movie]
    let total: Int?
    let pages: Int?
}

class NeoMoviesService {
    static let shared = NeoMoviesService()

    private let base = "https://api.neomovies.ru/api/v1"

    private func fetch<T: Codable>(_ path: String, type: T.Type) async throws -> T {
        guard let url = URL(string: base + path) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(type, from: data)
    }

    func getPopular(page: Int = 1) async throws -> [Movie] {
        let response = try await fetch("/movies/popular?page=\(page)", type: NeoEnvelope<NeoMediaResponse>.self)
        return response.data.results
    }

    func getTopRated(page: Int = 1) async throws -> [Movie] {
        let response = try await fetch("/movies/top-rated?page=\(page)", type: NeoEnvelope<NeoMediaResponse>.self)
        return response.data.results
    }

    func getTopTv(page: Int = 1) async throws -> [Movie] {
        let response = try await fetch("/tv/top-rated?page=\(page)", type: NeoEnvelope<NeoMediaResponse>.self)
        return response.data.results
    }

    func search(query: String, page: Int = 1) async throws -> [Movie] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let response = try await fetch("/search?query=\(encoded)&page=\(page)", type: NeoEnvelope<NeoMediaResponse>.self)
        return response.data.results
    }
}
