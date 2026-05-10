import Foundation

@MainActor
class PlayerRepository {
    
    private let baseURL = "https://api.neomovies.ru/api/v1"
    private let cdnBaseURL = "https://api.rstprgapipt.com/balancer-api/proxy/playlists/catalog-api"
    
    // CDN Token from API source code
    private let cdnToken = "eyJhbGciOiJIUzI1NiJ9.eyJ3ZWJTaXRlIjoiMzQiLCJpc3MiOiJhcGktd2VibWFzdGVyIiwic3ViIjoiNDEiLCJpYXQiOjE3NDMwNjA3ODAsImp0aSI6IjIzMTQwMmE0LTM3NTMtNGQ3OS1hNDBjLTA2YTY0MTE0MzNhOSIsInNjb3BlIjoiRExFIn0.4PmKGf512P-ov-tEjwr3gfOVxccjx8SSt28slJXypYU"
    
    private var neoId: String?
    
    func setNeoId(_ neoId: String) {
        self.neoId = neoId
    }
    
    // MARK: - Main Method
    
    func getVideoSource(kpId: Int, season: Int? = nil, episode: Int? = nil) async throws -> VideoSource {
        
        // 1. Try CDN first (direct m3u8 links)
        do {
            print("Trying CDN for kpId: \(kpId)")
            let source = try await tryCDN(kpId: kpId, season: season, episode: episode)
            print("CDN success!")
            return source
        } catch {
            print("CDN failed: \(error)")
        }
        
        // 2. Try Alloha
        do {
            print("Trying Alloha...")
            let source = try await tryAlloha(kpId: kpId, season: season, episode: episode)
            print("Alloha success!")
            return source
        } catch {
            print("Alloha failed: \(error)")
        }
        
        // 3. Try Collaps
        do {
            print("Trying Collaps...")
            let source = try await tryCollaps(kpId: kpId, season: season, episode: episode)
            print("Collaps success!")
            return source
        } catch {
            print("Collaps failed: \(error)")
        }
        
        throw PlayerError.noAvailableSource
    }
    
    // MARK: - CDN API
    
    private func tryCDN(kpId: Int, season: Int?, episode: Int?) async throws -> VideoSource {
        // Step 1: Resolve CDN ID from KP ID
        let cdnId = try await resolveCDNId(kpId: kpId)
        print("Resolved CDN ID: \(cdnId)")
        
        // Step 2: Get content info
        let contentInfo = try await getCDNContentInfo(cdnId: cdnId)
        print("Content info - hasMultipleEpisodes: \(contentInfo.hasMultipleEpisodes)")
        
        if contentInfo.hasMultipleEpisodes {
            // TV Show - get episodes
            let episodes = try await getCDNEpisodes(cdnId: cdnId)
            print("Got \(episodes.count) episodes")
            
            let targetSeason = season ?? 1
            let targetEpisode = episode ?? 1
            
            guard let selectedEpisode = episodes.first(where: { $0.season.order == targetSeason && $0.order == targetEpisode }),
                  let variant = selectedEpisode.episodeVariants.first else {
                throw PlayerError.episodeNotFound
            }
            
            print("Selected S\(targetSeason)E\(targetEpisode), filepath: \(variant.filepath)")
            
            let m3u8Url = try await resolveM3U8(filepath: variant.filepath)
            print("Resolved m3u8: \(m3u8Url)")
            
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
            // Movie
            guard let trailerUrl = contentInfo.trailerUrls?.first else {
                throw PlayerError.noVideoSource
            }
            
            print("Movie trailer URL: \(trailerUrl)")
            
            let m3u8Url = try await resolveM3U8(filepath: trailerUrl)
            print("Resolved m3u8: \(m3u8Url)")
            
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
        
        // Extract MOVIE_ID from HTML
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
    
    // MARK: - Fallback Balancers (Simplified)
    
    private func tryAlloha(kpId: Int, season: Int?, episode: Int?) async throws -> VideoSource {
        var url = "\(baseURL)/players/alloha/kp/\(kpId)"
        if let season = season, let episode = episode {
            url += "?season=\(season)&episode=\(episode)"
        }
        
        var request = URLRequest(url: URL(string: url)!)
        if let neoId = neoId {
            request.setValue("Bearer \(neoId)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlayerError.balancerFailed
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw PlayerError.invalidResponse
        }
        
        // Extract iframe src from HTML
        guard let srcRange = html.range(of: 