import Foundation

class AllohaRepository: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private var session: URLSession!

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func getIframeUrl(kpId: Int, season: Int? = nil, episode: Int? = nil) async throws -> String {
        var urlString = "https://api.neomovies.ru/api/v1/players/alloha/kp/\(kpId)"
        if let season, let episode {
            urlString += "?season=\(season)&episode=\(episode)"
        }

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotParseResponse)
        }

        if let srcRange = html.range(of: "src=\""),
           let endRange = html[srcRange.upperBound...].range(of: "\"") {
            let iframeUrl = String(html[srcRange.upperBound..<endRange.lowerBound])
            if !iframeUrl.isEmpty && iframeUrl.hasPrefix("http") {
                return iframeUrl
            }
        }

        throw URLError(.cannotParseResponse)
    }
}
