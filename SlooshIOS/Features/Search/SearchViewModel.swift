import Foundation
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String? = nil
    
    private var currentPage = 1
    private var canLoadMore = true
    private var searchTask: Task<Void, Never>?
    
    func performSearch() {
        searchTask?.cancel()
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            self.movies = []
            self.errorMessage = nil
            self.isLoading = false
            return
        }
        
        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            
            self.isLoading = true
            self.errorMessage = nil
            self.currentPage = 1
            
            do {
                let fetched = try await NeoMoviesService.shared.search(query: query, page: currentPage)
                guard !Task.isCancelled else { return }
                self.movies = fetched
                self.canLoadMore = !fetched.isEmpty
                if fetched.isEmpty {
                    self.errorMessage = "Ничего не найдено"
                }
                self.isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = "Ошибка поиска"
                self.isLoading = false
            }
        }
    }
    
    func loadMoreIfNeeded(currentMovie: Movie) async {
        guard let last = movies.last else { return }
        if last.id == currentMovie.id && canLoadMore && !isLoadingMore {
            await loadNextPage()
        }
    }
    
    private func loadNextPage() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let fetched = try await NeoMoviesService.shared.search(query: query, page: currentPage)
            if fetched.isEmpty {
                canLoadMore = false
            } else {
                let newMovies = fetched.filter { newMovie in
                    !self.movies.contains(where: { $0.id == newMovie.id })
                }
                self.movies.append(contentsOf: newMovies)
            }
            self.isLoadingMore = false
        } catch {
            self.isLoadingMore = false
            self.currentPage -= 1
        }
    }
}
