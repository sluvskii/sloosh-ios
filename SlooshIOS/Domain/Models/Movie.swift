import SwiftUI

struct Movie: Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let rating: Double
    let year: String
    let genre: String
    let duration: String
    let posterColor: Color
    let coverImageName: String?
    
    init(id: UUID = UUID(), title: String, description: String, rating: Double, year: String, genre: String, duration: String, posterColor: Color, coverImageName: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.rating = rating
        self.year = year
        self.genre = genre
        self.duration = duration
        self.posterColor = posterColor
        self.coverImageName = coverImageName
    }
}
