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

class PlayerService {
    static let shared = PlayerService()
    
    private let cdnToken = "eyJhbGciOiJIUzI1NiJ9.eyJ3ZWJTaXRlIjoiMzQiLCJpc3MiOiJhcGktd2VibWFzdGVyIiwic3ViIjoiNDEiLCJpYXQiOjE3NDMwNjA3ODAsImp0aSI6IjIzMTQwMmE0LTM3NTMtNGQ3OS1hNDBjLTA2YTY0MTE0MzNhOSIsInNjb3BlIjoiRExFIn0.4PmKGf512P-ov-tEjwr3gfOVxccjx8SSt28slJXypYU"
    
    struct CDNContentInfo: Codable {
        let id: Int
        let title: String
        let hasMultipleEpisodes: Bool
        let trailerUrls: [String]?
    }

    struct CDNEpisode: Codable {
        let id: Int
        let title: String
        let order: Int
        let season: CDNSeason
        let episodeVariants: [CDNVariant]?
    }

    struct CDNSeason: Codable {
        let id: Int
        let order: Int
    }

    struct CDNVariant: Codable {
        let filepath: String
    }
    
    private func getHeaders() -> [String: String] {
        return [
            "DLE-API-TOKEN": cdnToken,
            "Iframe-Request-Id": "7f2a4c1b-ca44-4858-b6ab-71894c7bb1aa"
        ]
    }
    
    func resolveCDNId(kpId: String) async throws -> Int {
        let urlString = "https://api.rstprgapipt.com/balancer-api/iframe?kp=\(kpId)&token=\(cdnToken)&disabled_share=1"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else { throw URLError(.badServerResponse) }
        
        if let range = html.range(of: "window.MOVIE_ID=") {
            let substring = html[range.upperBound...]
            if let endRange = substring.range(of: ";") {
                let idStr = String(substring[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if let id = Int(idStr) {
                    return id
                }
            }
        }
        throw URLError(.cannotParseResponse)
    }
    
    func getCDNContentInfo(cdnId: Int) async throws -> CDNContentInfo {
        let url = URL(string: "https://api.rstprgapipt.com/balancer-api/proxy/playlists/catalog-api/contents/\(cdnId)")!
        var request = URLRequest(url: url)
        for (k, v) in getHeaders() { request.addValue(v, forHTTPHeaderField: k) }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CDNContentInfo.self, from: data)
    }

    func getCDNEpisodes(cdnId: Int) async throws -> [CDNEpisode] {
        let url = URL(string: "https://api.rstprgapipt.com/balancer-api/proxy/playlists/catalog-api/episodes?content-id=\(cdnId)")!
        var request = URLRequest(url: url)
        for (k, v) in getHeaders() { request.addValue(v, forHTTPHeaderField: k) }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([CDNEpisode].self, from: data)
    }
    
    func getDirectM3U8(kpId: String, season: Int? = nil, episode: Int? = nil) async throws -> URL {
        let cleanId = kpId.replacingOccurrences(of: "kp_", with: "")
        let cdnId = try await resolveCDNId(kpId: cleanId)
        let info = try await getCDNContentInfo(cdnId: cdnId)
        
        var m3u8UrlString: String
        
        if !info.hasMultipleEpisodes {
            guard let urls = info.trailerUrls, let url = urls.first else { throw URLError(.cannotFindHost) }
            m3u8UrlString = url
        } else {
            let episodes = try await getCDNEpisodes(cdnId: cdnId)
            let targetSeason = season ?? 1
            let targetEpisode = episode ?? 1
            
            let ep = episodes.first { $0.season.order == targetSeason && $0.order == targetEpisode } ?? episodes.first
            guard let variant = ep?.episodeVariants?.first else { throw URLError(.cannotFindHost) }
            m3u8UrlString = variant.filepath
        }
        
        if m3u8UrlString.hasPrefix("//") {
            m3u8UrlString = "https:" + m3u8UrlString
        } else if m3u8UrlString.hasPrefix("/") {
            m3u8UrlString = "https://api.rstprgapipt.com" + m3u8UrlString
        }
        
        guard let initialUrl = URL(string: m3u8UrlString) else { throw URLError(.badURL) }
        
        // Мы убрали ручной resolveRedirect, потому что AVPlayer (AVURLAsset) 
        // сам отлично следует по 302/307 редиректам, 
        // плюс мы сможем прокинуть нужные заголовки прямо в AVURLAsset.
        return initialUrl
    }
}