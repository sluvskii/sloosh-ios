import Foundation

struct Translation: Identifiable, Hashable {
    let id: String
    let name: String
}

struct Episode: Identifiable, Hashable {
    let id: String
    let title: String
    let number: Int
    let streamURL: URL?
}

struct Season: Identifiable, Hashable {
    let id: String
    let number: Int
    let episodes: [Episode]
}

// Заглушки для UI
extension Translation {
    static let mocks = [
        Translation(id: "1", name: "Дубляж (LostFilm)"),
        Translation(id: "2", name: "Кубик в Кубе"),
        Translation(id: "3", name: "Оригинал (ENG)")
    ]
}

extension Season {
    static let mocks = [
        Season(id: "s1", number: 1, episodes: [
            Episode(id: "e1", title: "Пилот", number: 1, streamURL: nil),
            Episode(id: "e2", title: "Долгая дорога", number: 2, streamURL: nil),
            Episode(id: "e3", title: "Буря", number: 3, streamURL: nil)
        ]),
        Season(id: "s2", number: 2, episodes: [
            Episode(id: "e4", title: "Возвращение", number: 1, streamURL: nil),
            Episode(id: "e5", title: "Новая угроза", number: 2, streamURL: nil)
        ])
    ]
}
