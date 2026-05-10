import Foundation

enum PlayerError: Error, LocalizedError {
    case noAvailableSource
    case cdnResolutionFailed
    case cdnIdNotFound
    case contentInfoFailed
    case episodesFailed
    case episodeNotFound
    case noVideoSource
    case balancerFailed
    case invalidResponse
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .noAvailableSource:
            return "Нет доступного источника видео"
        case .cdnResolutionFailed:
            return "Ошибка резолва CDN"
        case .cdnIdNotFound:
            return "CDN ID не найден"
        case .contentInfoFailed:
            return "Ошибка получения информации о контенте"
        case .episodesFailed:
            return "Ошибка получения списка эпизодов"
        case .episodeNotFound:
            return "Эпизод не найден"
        case .noVideoSource:
            return "Источник видео не найден"
        case .balancerFailed:
            return "Ошибка балансера"
        case .invalidResponse:
            return "Некорректный ответ сервера"
        case .invalidURL:
            return "Некорректный URL"
        }
    }
}
