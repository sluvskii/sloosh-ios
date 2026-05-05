Привет! Мы продолжаем разработку iOS-приложения для просмотра фильмов и сериалов "sloosh" (название всегда пишется с маленькой буквы). Разработка ведется на Windows без использования Mac, поэтому сборка `.ipa` настроена через GitHub Actions, а установка на iPhone происходит через Sideloadly.

**Что уже сделано в проекте:**
1. Настроена базовая архитектура на SwiftUI (iOS 18.0 target).
2. Настроены CI/CD пайплайны, которые успешно собирают и отдают unsigned `.ipa` файл из `.xcarchive` прямо в GitHub Releases.
3. Реализована навигация через `TabView` (Главная, Поиск, Профиль).
4. Установлен фирменный акцентный цвет: кислотно-желто-зеленый (`#B3FF00`).
5. Настроен сетевой слой (`NeoMoviesService`) и экраны (Home, MovieDetail) получают реальные данные с бэкенда (`api.neomovies.ru`). 
6. Интегрирован балансер Alloha: есть парсинг страниц через невидимый `WKWebView`, обход 403 Forbidden через подстановку заголовков (HLS Proxy в `AVAssetResourceLoaderDelegate`) и игнорирование просроченных SSL-сертификатов (через делегаты `URLSession` и `NSAppTransportSecurity`).

**ЗАДАЧА ДЛЯ СЛЕДУЮЩЕГО АГЕНТА:**
# Промт для AI агента — iOS приложение Sloosh

## Контекст

Ты работаешь над iOS приложением **Sloosh** — стриминговый клиент для просмотра фильмов и сериалов с нативным AVPlayer. Приложение написано на Swift + SwiftUI. Структура проекта уже существует, нужно исправить и дополнить несколько файлов.

---

## Стек и архитектура

- Swift + SwiftUI
- AVPlayer для воспроизведения HLS видео
- WKWebView (скрытый) для парсинга Alloha iframe
- NeoMovies API v2 как бэкенд (базовый URL: `https://api.neomovies.ru/api/v1`)

---

## NeoMovies API — полная документация

### Базовый URL
```
https://api.neomovies.ru/api/v1
```

### Формат успешного ответа
```json
{ "success": true, "data": { ... } }
```

### Формат ошибки
```json
{ "error": "описание ошибки" }
```

### Эндпоинты (все без авторизации кроме /favorites)

#### Популярные фильмы
```
GET /movies/popular?page=1
```
Ответ:
```json
{
  "success": true,
  "data": {
    "results": [
      {
        "id": "kp_326",
        "title": "Матрица",
        "originalTitle": "The Matrix",
        "year": 1999,
        "rating": 8.5,
        "posterUrl": "/api/v1/images/kp_small/326",
        "backdropUrl": "/api/v1/images/kp_big/326",
        "description": "...",
        "type": "movie",
        "genres": [{ "id": "1", "name": "фантастика" }],
        "externalIds": { "kp": 326, "tmdb": 603, "imdb": "tt0133093" }
      }
    ],
    "total": 100,
    "pages": 10
  }
}
```

#### Топ фильмы
```
GET /movies/top-rated?page=1
```
Ответ аналогичен popular.

#### Топ сериалы
```
GET /tv/top-rated?page=1
```

#### Поиск
```
GET /search?query=матрица&page=1
```
Ответ аналогичен popular (то же поле `results`).

#### Детали фильма
```
GET /movie/kp_326
```
Ответ:
```json
{
  "success": true,
  "data": {
    "id": "kp_326",
    "title": "Матрица",
    "originalTitle": "The Matrix",
    "description": "...",
    "releaseDate": "1999-03-31",
    "type": "movie",
    "genres": [{ "id": "1", "name": "фантастика" }],
    "rating": 8.5,
    "posterUrl": "/api/v1/images/kp_small/326",
    "backdropUrl": "/api/v1/images/kp_big/326",
    "duration": 136,
    "country": "США",
    "language": "en",
    "externalIds": { "kp": 326, "tmdb": 603, "imdb": "tt0133093" }
  }
}
```

#### Изображения
Постеры и обложки — относительные пути, нужно добавлять базовый URL:
```
https://api.neomovies.ru/api/v1/images/kp_small/326   // постер (маленький)
https://api.neomovies.ru/api/v1/images/kp_big/326     // обложка (большой)
```

#### Плеер — САМЫЙ ВАЖНЫЙ ЭНДПОИНТ
```
GET /players/alloha/kp/326
GET /players/alloha/kp/326?season=1&episode=1   // для сериалов
GET /players/hdvb/kp/326
GET /players/collaps/kp/326
GET /players/lumex/kp/326
GET /players/vibix/kp/326
```
Возвращает **HTML страницу** с iframe:
```html
<!DOCTYPE html>
<html>
  <body style="margin:0">
    <iframe src="https://alloha.tv/..." width="100%" height="100%" ...></iframe>
  </body>
</html>
```
**Авторизация НЕ НУЖНА.** Из этого HTML нужно извлечь `src` атрибут iframe тега — это и есть URL для AllohaParser.

---

## Как работает воспроизведение (полная схема)

```
1. NeoMoviesService.getPopular() → список фильмов с posterUrl, id (например "kp_326")
2. Пользователь нажимает на фильм
3. AllohaRepository.getIframeUrl(kpId: 326) →
   GET https://api.neomovies.ru/api/v1/players/alloha/kp/326 →
   парсим src из <iframe src="..."> → получаем iframeUrl типа "https://alloha.tv/..."
4. AllohaParser.parse(iframeUrl: iframeUrl) →
   грузит iframe в скрытый WKWebView →
   JS перехватывает XHR/fetch запросы внутри iframe →
   извлекает m3u8 URL и заголовки (authorizations, accepts-controls и др.)
5. AllohaParser вызывает делегат onM3u8Refreshed(url:, extraHeaders:)
6. AllohaPlayerViewModel создаёт AVURLAsset с кастомной схемой "alloha-https://"
7. AllohaResourceLoaderDelegate перехватывает запросы AVPlayer,
   проксирует их через URLSession с правильными заголовками
8. AVPlayer воспроизводит HLS поток
```

---

## Файлы которые нужно исправить

### 1. `NeoMoviesService.swift` — ПОЛНОСТЬЮ ПЕРЕПИСАТЬ

Текущая версия использует неверную структуру ответа. Правильная модель:

```swift
import Foundation

// MARK: - API Models

struct NeoEnvelope<T: Codable>: Codable {
    let success: Bool
    let data: T
}

struct NeoMediaResponse: Codable {
    let results: [NeoMovie]
    let total: Int?
    let pages: Int?
}

struct NeoMovie: Codable {
    let id: String           // "kp_326"
    let title: String
    let originalTitle: String?
    let year: Int?
    let rating: Double?
    let posterUrl: String?   // "/api/v1/images/kp_small/326" — относительный путь!
    let backdropUrl: String? // "/api/v1/images/kp_big/326"
    let description: String?
    let type: String?        // "movie" или "tv"
    let genres: [NeoGenre]?
    let externalIds: NeoExternalIds?
    
    // Вспомогательное свойство — полный URL постера
    var fullPosterUrl: String? {
        guard let path = posterUrl else { return nil }
        if path.hasPrefix("http") { return path }
        return "https://api.neomovies.ru" + path
    }
    
    var fullBackdropUrl: String? {
        guard let path = backdropUrl else { return nil }
        if path.hasPrefix("http") { return path }
        return "https://api.neomovies.ru" + path
    }
    
    // Kinopoisk ID как Int (для передачи в AllohaRepository)
    var kpId: Int? {
        // id приходит как "kp_326" или просто "326"
        let clean = id.replacingOccurrences(of: "kp_", with: "")
        return Int(clean)
    }
}

struct NeoGenre: Codable {
    let id: String?
    let name: String?
}

struct NeoExternalIds: Codable {
    let kp: Int?
    let tmdb: Int?
    let imdb: String?
}

// MARK: - Service

class NeoMoviesService {
    static let shared = NeoMoviesService()
    private let base = "https://api.neomovies.ru/api/v1"
    
    private func fetch<T: Codable>(_ path: String, type: T.Type) async throws -> T {
        guard let url = URL(string: base + path) else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func getPopular(page: Int = 1) async throws -> [NeoMovie] {
        let r = try await fetch("/movies/popular?page=\(page)", type: NeoEnvelope<NeoMediaResponse>.self)
        return r.data.results
    }
    
    func getTopRated(page: Int = 1) async throws -> [NeoMovie] {
        let r = try await fetch("/movies/top-rated?page=\(page)", type: NeoEnvelope<NeoMediaResponse>.self)
        return r.data.results
    }
    
    func getTopTv(page: Int = 1) async throws -> [NeoMovie] {
        let r = try await fetch("/tv/top-rated?page=\(page)", type: NeoEnvelope<NeoMediaResponse>.self)
        return r.data.results
    }
    
    func search(query: String, page: Int = 1) async throws -> [NeoMovie] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let r = try await fetch("/search?query=\(encoded)&page=\(page)", type: NeoEnvelope<NeoMediaResponse>.self)
        return r.data.results
    }
}
```

### 2. `AllohaRepository.swift` — ПОЛНОСТЬЮ ПЕРЕПИСАТЬ

Старая версия пытается напрямую обращаться к `api.alloha.tv` с токеном — это НЕВЕРНО. Нужно использовать NeoMovies API:

```swift
import Foundation

class AllohaRepository: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private var session: URLSession!
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // Игнорируем TLS ошибки (нужно для некоторых CDN доменов)
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
    
    /// Получает iframe URL через NeoMovies API и парсит его из HTML
    func getIframeUrl(kpId: Int, season: Int? = nil, episode: Int? = nil) async throws -> String {
        var urlString = "https://api.neomovies.ru/api/v1/players/alloha/kp/\(kpId)"
        if let s = season, let e = episode {
            urlString += "?season=\(s)&episode=\(e)"
        }
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, response) = try await session.data(from: url)
        
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        // Парсим src="..." из <iframe src="...">
        // HTML выглядит так: <iframe src="https://alloha.tv/..." width="100%" ...>
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
```

### 3. `AllohaPlayerViewModel.swift` — ИСПРАВИТЬ метод loadVideo

Нужно заменить вызов `repository.getContent(kpId:)` на `repository.getIframeUrl(kpId:)`:

```swift
func loadVideo(for movie: Movie) async {
    self.currentMovie = movie
    self.isLoading = true
    self.errorMessage = nil
    self.player?.pause()
    self.player = nil
    
    // Извлекаем числовой kpId из строки типа "kp_326"
    let kpIdStr = movie.id.replacingOccurrences(of: "kp_", with: "")
    guard let kpId = Int(kpIdStr) else {
        self.errorMessage = "Неверный ID фильма: \(movie.id)"
        self.isLoading = false
        return
    }
    
    do {
        // Шаг 1: получаем iframe URL через NeoMovies API
        let iframeUrl = try await repository.getIframeUrl(kpId: kpId)
        
        // Шаг 2: запускаем парсер (загружает iframe в скрытый WebView)
        self.parser = AllohaParser()
        self.parser?.delegate = self
        self.parser?.parse(iframeUrl: iframeUrl)
        
        // Дальше делегат AllohaParserDelegate вызовет onM3u8Refreshed
        // который создаст AVPlayer
        
    } catch {
        self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
        self.isLoading = false
    }
}
```

### 4. `Movie.swift` — ПРИВЕСТИ В СООТВЕТСТВИЕ с NeoMovies API

Модель `Movie` должна совпадать с тем что возвращает NeoMovies API:

```swift
import Foundation

struct Movie: Identifiable, Codable, Hashable {
    let id: String          // "kp_326"
    let title: String
    let originalTitle: String?
    let year: Int?
    let rating: Double?
    let posterUrl: String?  // может быть относительным "/api/v1/images/kp_small/326"
    let backdropUrl: String?
    let description: String?
    let type: String?       // "movie" или "tv"
    let genres: [Genre]?
    let externalIds: ExternalIds?
    
    struct Genre: Codable, Hashable {
        let id: String?
        let name: String?
    }
    
    struct ExternalIds: Codable, Hashable {
        let kp: Int?
        let tmdb: Int?
        let imdb: String?
    }
    
    // Полный URL постера
    var fullPosterUrl: String? {
        guard let path = posterUrl else { return nil }
        if path.hasPrefix("http") { return path }
        return "https://api.neomovies.ru" + path
    }
    
    var fullBackdropUrl: String? {
        guard let path = backdropUrl else { return nil }
        if path.hasPrefix("http") { return path }
        return "https://api.neomovies.ru" + path
    }
    
    // Kinopoisk ID для передачи в AllohaRepository
    var kpId: Int? {
        let clean = id.replacingOccurrences(of: "kp_", with: "")
        return Int(clean)
    }
    
    var isSerial: Bool {
        type == "tv"
    }
}
```

### 5. `Info.plist` — ДОБАВИТЬ разрешение на произвольные сетевые запросы

Обязательно добавить в Info.plist (иначе AVPlayer будет падать с TLS ошибкой на CDN серверах):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## Структура проекта

```
SlooshIOS/
├── App/
│   ├── SlooshIOSApp.swift
│   └── RootView.swift
├── Core/
│   └── Network/
│       └── Alloha/
│           ├── AllohaModels.swift
│           ├── AllohaParser.swift          ← НЕ ТРОГАТЬ
│           ├── AllohaRepository.swift      ← ПЕРЕПИСАТЬ
│           └── AllohaResourceLoaderDelegate.swift  ← НЕ ТРОГАТЬ
├── Domain/
│   └── Models/
│       └── Movie.swift                     ← ИСПРАВИТЬ
├── Features/
│   ├── Home/
│   │   └── HomeView.swift
│   ├── MovieDetail/
│   │   ├── AllohaPlayerViewModel.swift     ← ИСПРАВИТЬ
│   │   └── MovieDetailView.swift
│   └── Search/
│       └── SearchView.swift
└── NeoMoviesService.swift                  ← ПЕРЕПИСАТЬ
```

---

## Проверка что всё работает

После исправлений поток должен быть такой:

1. `HomeView` загружает фильмы через `NeoMoviesService.getPopular()` → список `[Movie]`
2. Постеры отображаются через `movie.fullPosterUrl`
3. При нажатии на фильм открывается `MovieDetailView` с `AllohaPlayerViewModel`
4. `viewModel.loadVideo(for: movie)` вызывает `repository.getIframeUrl(kpId: movie.kpId!)`
5. `AllohaParser` загружает iframe, перехватывает m3u8
6. `onM3u8Refreshed` создаёт AVPlayer с кастомным ResourceLoader
7. Фильм воспроизводится в нативном AVPlayer

---

## Частые ошибки которые нужно избежать

1. **НЕ** обращаться напрямую к `api.alloha.tv` — только через NeoMovies API
2. **НЕ** использовать старый токен `ffbd312217e27c4245f2678afe1881` — он не нужен
3. **НЕ** трогать `AllohaParser.swift` и `AllohaResourceLoaderDelegate.swift`
4. posterUrl из API **относительный** (`/api/v1/images/...`), нужно добавлять `https://api.neomovies.ru`
5. id фильма приходит как `"kp_326"` — для AllohaRepository нужно убрать префикс и получить `326`
6. Info.plist **обязательно** должен иметь `NSAllowsArbitraryLoads = true`
