import Foundation

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

let cdnToken = "eyJhbGciOiJIUzI1NiJ9.eyJ3ZWJTaXRlIjoiMzQiLCJpc3MiOiJhcGktd2VibWFzdGVyIiwic3ViIjoiNDEiLCJpYXQiOjE3NDMwNjA3ODAsImp0aSI6IjIzMTQwMmE0LTM3NTMtNGQ3OS1hNDBjLTA2YTY0MTE0MzNhOSIsInNjb3BlIjoiRExFIn0.4PmKGf512P-ov-tEjwr3gfOVxccjx8SSt28slJXypYU"

func getHeaders() -> [String: String] {
    return [
        "DLE-API-TOKEN": cdnToken,
        "Iframe-Request-Id": "7f2a4c1b-ca44-4858-b6ab-71894c7bb1aa"
    ]
}

func run() async throws {
    let kpId = "1143242" // The Gentlemen
    let urlString = "https://api.rstprgapipt.com/balancer-api/iframe?kp=\(kpId)&token=\(cdnToken)&disabled_share=1"
    let (data, _) = try await URLSession.shared.data(from: URL(string: urlString)!)
    let html = String(data: data, encoding: .utf8)!
    
    guard let range = html.range(of: "window.MOVIE_ID=") else { print("No MOVIE_ID"); return }
    let sub = html[range.upperBound...]
    guard let end = sub.range(of: ";") else { print("No ;"); return }
    let idStr = String(sub[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    guard let cdnId = Int(idStr) else { print("Not int"); return }
    print("CDN ID:", cdnId)
    
    let infoUrl = URL(string: "https://api.rstprgapipt.com/balancer-api/proxy/playlists/catalog-api/contents/\(cdnId)")!
    var req = URLRequest(url: infoUrl)
    for (k,v) in getHeaders() { req.addValue(v, forHTTPHeaderField: k) }
    let (infoData, _) = try await URLSession.shared.data(for: req)
    let info = try JSONDecoder().decode(CDNContentInfo.self, from: infoData)
    print("Info:", info.title)
    
    var filepath = ""
    if !info.hasMultipleEpisodes {
        filepath = info.trailerUrls?.first ?? ""
    } else {
        let epUrl = URL(string: "https://api.rstprgapipt.com/balancer-api/proxy/playlists/catalog-api/episodes?content-id=\(cdnId)")!
        var epReq = URLRequest(url: epUrl)
        for (k,v) in getHeaders() { epReq.addValue(v, forHTTPHeaderField: k) }
        let (epData, _) = try await URLSession.shared.data(for: epReq)
        let eps = try JSONDecoder().decode([CDNEpisode].self, from: epData)
        filepath = eps.first?.episodeVariants?.first?.filepath ?? ""
    }
    
    print("Filepath:", filepath)
    
    class Del: NSObject, URLSessionTaskDelegate {
        var finalURL: URL?
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            print("Redirect to:", request.url?.absoluteString ?? "nil")
            finalURL = request.url
            completionHandler(nil)
        }
    }
    
    let del = Del()
    let session = URLSession(configuration: .default, delegate: del, delegateQueue: nil)
    var r = URLRequest(url: URL(string: filepath)!)
    r.httpMethod = "GET"
    _ = try? await session.data(for: r)
    print("Final URL:", del.finalURL?.absoluteString ?? "No redirect")
}

let sema = DispatchSemaphore(value: 0)
Task {
    do { try await run() } catch { print(error) }
    sema.signal()
}
sema.wait()
