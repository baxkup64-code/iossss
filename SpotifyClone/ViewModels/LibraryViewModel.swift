import Foundation
import SwiftData

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var playlists: [PlaylistEntity] = []
    @Published var likedSongsCount: Int = 0

    private var modelContext: ModelContext?

    func attach(_ context: ModelContext) {
        modelContext = context
        refresh()
    }

    func refresh() {
        guard let modelContext else { return }
        let playlistDescriptor = FetchDescriptor<PlaylistEntity>(sortBy: [.init(\.createdAt, order: .reverse)])
        playlists = (try? modelContext.fetch(playlistDescriptor)) ?? []

        let likedDescriptor = FetchDescriptor<LikedTrackEntity>()
        likedSongsCount = (try? modelContext.fetchCount(likedDescriptor)) ?? 0
    }

    func createPlaylist(name: String, emoji: String) {
        guard let modelContext, !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        modelContext.insert(PlaylistEntity(name: name, coverEmoji: emoji))
        try? modelContext.save()
        refresh()
    }

    func deletePlaylist(_ playlist: PlaylistEntity) {
        guard let modelContext else { return }
        modelContext.delete(playlist)
        try? modelContext.save()
        refresh()
    }

    func rename(_ playlist: PlaylistEntity, to newName: String) {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        playlist.name = newName
        try? modelContext?.save()
        refresh()
    }

    func addTrack(_ track: Track, to playlist: PlaylistEntity) {
        guard let modelContext else { return }
        guard !playlist.tracks.contains(where: { $0.trackID == track.id }) else { return }
        let entry = PlaylistTrackEntity(track: track, sortIndex: playlist.tracks.count)
        entry.playlist = playlist
        modelContext.insert(entry)
        try? modelContext.save()
        refresh()
    }

    func removeTrack(_ track: PlaylistTrackEntity, from playlist: PlaylistEntity) {
        guard let modelContext else { return }
        modelContext.delete(track)
        try? modelContext.save()
        refresh()
    }

    func moveTracks(in playlist: PlaylistEntity, from source: IndexSet, to destination: Int) {
        var sorted = playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, track) in sorted.enumerated() { track.sortIndex = index }
        try? modelContext?.save()
        refresh()
    }
}
