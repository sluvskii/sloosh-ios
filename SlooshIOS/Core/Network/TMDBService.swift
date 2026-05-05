import Foundation

class TMDBService {
    static let shared = TMDBService()
    
    // TODO: Вставьте свой API ключ от TMDB
    private let apiKey = "966c4f4f" 
    private let baseURL = "https://api.themoviedb.org/3"
    
    struct TMDBResponse: Codable {
        let results: [Movie]
    }
    
    enum Endpoint {
        case trendingMovies
        case newSeries
        
        var path: String {
            switch self {
            case .trendingMovies: return "/trending/movie/week"
            case .newSeries: return "/trending/tv/week"
            }
        }
    }
    
    func fetch(endpoint: Endpoint) async throws -> [Movie] {
        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            throw URLError(.badURL)
        }
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "ru-RU")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let tmdbResponse = try decoder.decode(TMDBResponse.self, from: data)
        return tmdbResponse.results
    }
}
