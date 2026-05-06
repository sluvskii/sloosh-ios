import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String? = nil
    
    private var currentPage = 1
    private var canLoadMore = true
    
    func loadInitial() async {
        guard movies.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        do {
            let fetched = try await NeoMoviesService.shared.getPopular(page: currentPage)
            self.movies = fetched
            self.canLoadMore = !fetched.isEmpty
            self.isLoading = false
        } catch {
            self.errorMessage = "Не удалось загрузить фильмы.\nПроверьте подключение к сети."
            self.isLoading = false
        }
    }
    
    func loadMoreIfNeeded(currentMovie: Movie) async {
        guard let last = movies.last else { return }
        if last.id == currentMovie.id && canLoadMore && !isLoadingMore {
            await loadNextPage()
        }
    }
    
    private func loadNextPage() async {
        isLoadingMore = true
        currentPage += 1
        
        do {
            let fetched = try await NeoMoviesService.shared.getPopular(page: currentPage)
            if fetched.isEmpty {
                canLoadMore = false
            } else {
                // Remove duplicates just in case
                let newMovies = fetched.filter { newMovie in
                    !self.movies.contains(where: { $0.id == newMovie.id })
                }
                self.movies.append(contentsOf: newMovies)
            }
            self.isLoadingMore = false
        } catch {
            self.isLoadingMore = false
            self.currentPage -= 1 // revert page on error
        }
    }
    
    func refresh() async {
        canLoadMore = true
        currentPage = 1
        do {
            let fetched = try await NeoMoviesService.shared.getPopular(page: currentPage)
            self.movies = fetched
        } catch {
            // handle error if needed
        }
    }
}
