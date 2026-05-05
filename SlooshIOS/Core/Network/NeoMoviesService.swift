import Foundation

class NeoMoviesService {
    static let shared = NeoMoviesService()
    
    private let baseURL = "https://api.neomovies.ru/api/v1"
    
    struct NeoResponse<T: Codable>: Codable {
        let success: Bool
        let data: NeoData<T>
    }
    
    struct NeoData<T: Codable>: Codable {
        let results: T
        let total: Int?
        let pages: Int?
    }
    
    enum Endpoint {
        case popularMovies
        case topRatedSeries
        
        var path: String {
            switch self {
            case .popularMovies: return "/movies/popular"
            case .topRatedSeries: return "/tv/top-rated"
            }
        }
    }
    
    func fetch(endpoint: Endpoint) async throws -> [Movie] {
        let urlString = baseURL + endpoint.path
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        
        do {
            let apiResponse = try decoder.decode(NeoResponse<[Movie]>.self, from: data)
            return apiResponse.data.results
        } catch {
            print("Failed to decode NeoMovies API response: \(error)")
            throw error
        }
    }
}