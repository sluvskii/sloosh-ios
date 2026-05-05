import SwiftUI
import WebKit

struct PlayerSelectionView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    
    @State private var playerURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                SlooshTheme.background.ignoresSafeArea()
                
                if let url = playerURL {
                    WebView(url: url)
                        .ignoresSafeArea()
                } else {
                    ProgressView("Загрузка плеера...")
                        .tint(SlooshTheme.accent)
                }
            }
            .navigationTitle(movie.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .tint(.primary)
                }
            }
            .onAppear {
                playerURL = NeoMoviesService.shared.fetchStreamURL(kpId: movie.id)
            }
        }
    }
}

// Обёртка над WKWebView для отображения веб-плеера
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Позволяем видео воспроизводиться внутри (без автоматического фуллскрина на iPhone)
        configuration.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
