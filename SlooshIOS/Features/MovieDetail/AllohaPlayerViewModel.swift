import Foundation
import AVFoundation

@MainActor
class AllohaPlayerViewModel: ObservableObject, AllohaParserDelegate {
    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private let repository = AllohaRepository()
    private var parser: AllohaParser?
    private var resourceLoaderDelegate: AllohaResourceLoaderDelegate?
    private var currentMovie: Movie?
    
    func loadVideo(for movie: Movie) async {
        self.currentMovie = movie
        self.isLoading = true
        self.errorMessage = nil
        self.player?.pause()
        self.player = nil
        
        guard let kpId = movie.kpId else {
            self.errorMessage = "Неверный ID фильма: \(movie.id)"
            self.isLoading = false
            return
        }
        
        do {
            let iframeUrl = try await repository.getIframeUrl(kpId: kpId)

            self.parser = AllohaParser()
            self.parser?.delegate = self
            self.parser?.parse(iframeUrl: iframeUrl)
        } catch {
            self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func cleanup() {
        player?.pause()
        player = nil
        parser?.release()
        parser = nil
        resourceLoaderDelegate = nil
    }
    
    // MARK: - AllohaParserDelegate
    
    func onHlsLinksReceived(json: String, extraHeaders: [String : String]) {
        // Мы можем извлечь master.m3u8 из jsonResponse, но обычно он приходит в onM3u8Refreshed
        print("Alloha: HlsLinksReceived headers: \(extraHeaders)")
    }
    
    func onConfigUpdate(edgeHash: String, ttlSeconds: Int, extraHeaders: [String : String]) {
        resourceLoaderDelegate?.updateHeaders(extraHeaders)
    }
    
    func onM3u8Refreshed(url: String, extraHeaders: [String : String]) {
        guard player == nil else { return } // Уже инициализирован
        
        guard let actualURL = URL(string: url) else {
            self.errorMessage = "Неверный URL m3u8"
            self.isLoading = false
            return
        }
        
        // Меняем схему, чтобы AVAssetResourceLoaderDelegate перехватил запрос
        var components = URLComponents(url: actualURL, resolvingAgainstBaseURL: false)
        if components?.scheme == "https" {
            components?.scheme = "alloha-https"
        } else if components?.scheme == "http" {
            components?.scheme = "alloha-http"
        }
        
        guard let customURL = components?.url else { return }
        
        self.resourceLoaderDelegate = AllohaResourceLoaderDelegate(headers: extraHeaders)
        
        let asset = AVURLAsset(url: customURL)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .global(qos: .userInitiated))
        
        let playerItem = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: playerItem)
        self.isLoading = false
        self.player?.play()
    }
    
    func onStreamHeadersUpdated(extraHeaders: [String : String]) {
        resourceLoaderDelegate?.updateHeaders(extraHeaders)
    }
    
    func onError(error: String) {
        self.errorMessage = error
        self.isLoading = false
    }
}
