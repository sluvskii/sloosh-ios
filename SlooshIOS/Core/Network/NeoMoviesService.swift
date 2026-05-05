import Foundation

class NeoMoviesService {
    static let shared = NeoMoviesService()
    
    // Используем открытое API NeoMovies, которое работает как прокси к TMDB/Кинопоиску
    private let baseURL = "https://neomovies-api.vercel.app/api/v1"
    
    struct NeoResponse: Codable {
        let results: [Movie]
    }
    
    enum Endpoint {
        case trendingMovies
        case newSeries
        
        var path: String {
            switch self {
            case .trendingMovies: return "/movies/popular"
            case .newSeries: return "/movies/top-rated" // В API пока нет отдельного эндпоинта для трендовых сериалов, используем top-rated как заглушку
            }
        }
    }
    
    func fetch(endpoint: Endpoint) async throws -> [Movie] {
        // Пробуем сначала v1 API, если оно недоступно - переключимся на корневые эндпоинты
        var urlString = baseURL + endpoint.path
        
        // В разных версиях NeoMovies API пути немного отличаются.
        // Судя по документации старой версии, эндпоинты лежат в корне:
        urlString = "https://neomovies-api.vercel.app" + endpoint.path
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        
        // В зависимости от ответа API может возвращать либо массив напрямую, либо объект с полем results
        do {
            let tmdbResponse = try decoder.decode(NeoResponse.self, from: data)
            return tmdbResponse.results
        } catch {
            // Пробуем распарсить как прямой массив
            let movies = try decoder.decode([Movie].self, from: data)
            return movies
        }
    }
}
