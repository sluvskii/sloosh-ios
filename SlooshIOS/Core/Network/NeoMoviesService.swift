import Foundation

class NeoMoviesService {
    static let shared = NeoMoviesService()
    
    private let baseURL = "https://api.neomovies.ru/api/v1"
    
    struct NeoResponse<T: Codable>: Codable {
        let success: Bool
        let data: T
    }
    
    func fetchStream(kpId: String, season: Int? = nil, episode: Int? = nil) async throws -> StreamResponse {
        let urlString = baseURL + Endpoint.stream(kpId: kpId, season: season, episode: episode).path
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        
        do {
            let apiResponse = try decoder.decode(NeoResponse<StreamResponse>.self, from: data)
            return apiResponse.data
        } catch {
            print("Failed to decode stream response: \(error)")
            throw error
        }
    }
}
    
    struct NeoMoviesResponse<T: Codable>: Codable {
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
        case stream(kpId: String, season: Int?, episode: Int?)
        
        var path: String {
            switch self {
            case .popularMovies: return "/movies/popular"
            case .topRatedSeries: return "/tv/top-rated"
            case .stream(let kpId, let season, let episode):
                var base = "/stream/kp/\(kpId)"
                var params: [String] = []
                if let s = season { params.append("season=\(s)") }
                if let e = episode { params.append("episode=\(e)") }
                if !params.isEmpty {
                    base += "?" + params.joined(separator: "&")
                }
                return base
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
            let apiResponse = try decoder.decode(NeoMoviesResponse<[Movie]>.self, from: data)
            return apiResponse.data.results
        } catch {
            print("Failed to decode NeoMovies API response: \(error)")
            throw error
        }
    }
}