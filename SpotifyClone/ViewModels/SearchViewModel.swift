import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = "" {
        didSet { scheduleSearch() }
    }
    @Published var results = SearchResults()
    @Published var isSearching = false

    private let api = MusicAPIService.shared
    private var searchTask: Task<Void, Never>?

    enum Filter: String, CaseIterable, Identifiable {
        case all = "Alles", songs = "Songs", artists = "Künstler", albums = "Alben", playlists = "Playlists"
        var id: String { rawValue }
    }
    @Published var activeFilter: Filter = .all

    private func scheduleSearch() {
        searchTask?.cancel()
        let currentQuery = query
        guard !currentQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = SearchResults()
            return
        }
        searchTask = Task {
            // Debounce: wait a beat so we don't fire a request per keystroke.
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            isSearching = true
            let searchResults = await api.search(query: currentQuery)
            guard !Task.isCancelled else { return }
            self.results = searchResults
            self.isSearching = false
        }
    }
}
