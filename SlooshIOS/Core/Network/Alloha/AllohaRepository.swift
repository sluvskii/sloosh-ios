import Foundation

class AllohaRepository {
    private let token = "ffbd312217e27c4245f2678afe1881"
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        // We might need to disable some cache or handle certs, but default is fine for api.alloha.tv usually
        self.session = URLSession(configuration: configuration)
    }

    func getContent(kpId: Int) async throws -> AllohaContent {
        let urlString = "https://api.alloha.tv/?token=\(token)&kp=\(kpId)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await session.data(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let title = dataObj["name"] as? String ?? "Unknown"
        
        if let seasonsObj = dataObj["seasons"] as? [String: Any] {
            var seasons: [AllohaSeason] = []
            
            for (sKey, sValue) in seasonsObj {
                guard let sObj = sValue as? [String: Any],
                      let episodesObj = sObj["episodes"] as? [String: Any] else { continue }
                
                var episodes: [AllohaEpisode] = []
                
                for (eKey, eValue) in episodesObj {
                    guard let eObj = eValue as? [String: Any],
                          let transObj = eObj["translation"] as? [String: Any] else { continue }
                    
                    var translations: [AllohaTranslation] = []
                    
                    for (tKey, tValue) in transObj {
                        guard let tData = tValue as? [String: Any],
                              let iframe = tData["iframe"] as? String,
                              !iframe.isEmpty else { continue }
                        
                        translations.append(AllohaTranslation(
                            id: tKey,
                            name: tData["translation"] as? String ?? "Unknown",
                            iframeUrl: iframe
                        ))
                    }
                    
                    if !translations.isEmpty {
                        episodes.append(AllohaEpisode(
                            num: Int(eKey) ?? 0,
                            translations: translations.sorted { $0.name < $1.name }
                        ))
                    }
                }
                
                if !episodes.isEmpty {
                    seasons.append(AllohaSeason(
                        num: Int(sKey) ?? 0,
                        episodes: episodes.sorted { $0.num < $1.num }
                    ))
                }
            }
            
            return AllohaContent(
                title: title,
                isSerial: true,
                movieIframe: nil,
                seasons: seasons.sorted { $0.num < $1.num }
            )
        } else {
            let iframe = dataObj["iframe"] as? String ?? ""
            return AllohaContent(
                title: title,
                isSerial: false,
                movieIframe: iframe.isEmpty ? nil : iframe,
                seasons: []
            )
        }
    }
}
