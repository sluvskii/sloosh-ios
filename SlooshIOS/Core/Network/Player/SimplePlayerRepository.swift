import Foundation

@MainActor
class SimplePlayerRepository {
    
    private let baseURL = "https://api.neomovies.ru/api/v1"
    private let cdnBaseURL = "https://api.rstprgapipt.com/balancer-api/proxy/playlists/catalog-api"
    private let cdnToken = "eyJhbGciOiJIUzI1NiJ9.eyJ3ZWJTaXRlIjoiMzQiLCJpc3MiOiJhcGktd2VibWFzdGVyIiwic3ViIjoiNDEiLCJpYXQiOjE3NDMwNjA3ODAsImp0aSI6IjIzMTQwMmE0LTM3NTMtNGQ3OS1hNDBjLTA2YTY0MTE0MzNhOSIsInNjb3BlIjoiRExFIn0.4PmKGf512P-ov-tEjwr3gfOVxccjx8SSt28slJXypYU"
    
    private var neoId: String?
    
    func setNeoId(_ neoId: String) {
        self.neoId = neoId
    }
    
    func getVideoSource(kpId: Int, season: Int? = nil, episode: Int? = nil) async throws -> VideoSource {
        do {
            return try await tryCDN(kpId: kpId, season: season, episode: episode)
        } catch {
            print("CDN failed: \(error)")
            throw error
        }
    }
    
    private func tryCDN(kpId: Int, season: Int?, episode: Int?) async throws -> VideoSource {
        let cdnId = try await resolveCDNId(kpId: kpId)
        print("CDN ID: \(cdnId)")
        
        let contentInfo = try await getCDNContentInfo(cdnId: cdnId)
        print("Has multiple episodes: \(contentInfo.hasMultipleEpisodes)")
        
        if contentInfo.hasMultipleEpisodes {
            let episodes = try await getCDNEpisodes(cdnId: cdnId)
            print("Episodes count: \(episodes.count)")
            
            let targetSeason = season ?? 1
            let targetEpisode = episode ?? 1
            
            guard let selectedEpisode = episodes.first(where: { $0.season.order == targetSeason && $0.order == targetEpisode }),
                  let variant = selectedEpisode.episodeVariants.first else {
                throw PlayerError.episodeNotFound
            }
            
            let m3u8Url = try await resolveM3U8(filepath: variant.filepath)
            
            return VideoSource(
                url: m3u8Url,
                type: .cdn,
                title: contentInfo.title,
                season: targetSeason,
                episode: targetEpisode,
                isSeries: true,
                episodes: episodes.map { ep in
                    EpisodeInfo(
                        season: Int(ep.season.order),
                        episode: Int(ep.order),
                        title: ep.title,
                        m3u8Url: "",
                        translation: nil
                    )
                }
            )
        } else {
            guard let trailerUrl = contentInfo.trailerUrls?.first else {
                throw PlayerError.noVideoSource
            }
            
            let m3u8Url = try await resolveM3U8(filepath: trailerUrl)
            
            return VideoSource(
                url: m3u8Url,
                type: .cdn,
                title: contentInfo.title,
                season: nil,
                episode: nil,
                isSeries: false,
                episodes: []
            )
        }
    }
    
    private func resolveCDNId(kpId: Int) async throws -> UInt64 {
        let url = "https://api.rstprgapipt.com/balancer-api/iframe?kp=\(kpId)&token=\(cdnToken)&disabled_share=1"
        
        var request = URLRequest(url: URL(string: url)!)
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlayerError.cdnResolutionFailed
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw PlayerError.invalidResponse
        }
        
        guard let range = html.range(of: "window.MOVIE_ID=") else {
            throw PlayerError.cdnIdNotFound
        }
        
        let after = html[range.upperBound...]
        guard let endIndex = after.firstIndex(of: ";") ?? after.firstIndex(of: "\n") else {
            throw PlayerError.cdnIdNotFound
        }
        
        let idString = String(after[..<endIndex]).trimmingCharacters(in: .whitespaces)
        guard let cdnId = UInt64(idString) else {
            throw PlayerError.cdnIdNotFound
        }
        
        return cdnId
    }
    
    private func getCDNContentInfo(cdnId: UInt64) async throws -> CDNContentInfo {
        let url = "\(cdnBaseURL)/contents/\(cdnId)"
        
        var request = URLRequest(url: URL(string: url)!)
        request.setValue(cdnToken, forHTTPHeaderField: "DLE-API-TOKEN")
        request.setValue("7f2a4c1b-ca44-4858-b6ab-71894c7bb1aa", forHTTPHeaderField: "Iframe-Request-Id")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlayerError.contentInfoFailed
        }
        
        return try JSONDecoder().decode(CDNContentInfo.self, from: data)
    }
    
    private func getCDNEpisodes(cdnId: UInt64) async throws -> [CDNEpisode] {
        let url = "\(cdnBaseURL)/episodes?content-id=\(cdnId)"
        
        var request = URLRequest(url: URL(string: url)!)
        request.setValue(cdnToken, forHTTPHeaderField: "DLE-API-TOKEN")
        request.setValue("7f2a4c1b-ca44-4858-b6ab-71894c7bb1aa", forHTTPHeaderField: "Iframe-Request-Id")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlayerError.episodesFailed
        }
        
        return try JSONDecoder().decode([CDNEpisode].self, from: data)
    }
    
    private func resolveM3U8(filepath: String) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: URL(string: filepath)!)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 307 {
            if let location = httpResponse.allHeaderFields["Location"] as? String ?? httpResponse.value(forHTTPHeaderField: "Location") {
                return location
            }
        }
        
        return filepath
    }
}
