import Foundation

struct AllohaTranslation: Identifiable, Hashable {
    let id: String
    let name: String
    let iframeUrl: String
}

struct AllohaEpisode: Identifiable, Hashable {
    let id = UUID()
    let num: Int
    let translations: [AllohaTranslation]
}

struct AllohaSeason: Identifiable, Hashable {
    let id = UUID()
    let num: Int
    let episodes: [AllohaEpisode]
}

struct AllohaContent {
    let title: String
    let isSerial: Bool
    let movieIframe: String?
    let seasons: [AllohaSeason]
}
