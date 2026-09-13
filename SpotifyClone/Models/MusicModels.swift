import Foundation

/// Where a track's audio actually comes from. Kept as an enum so the player
/// can treat all sources uniformly while services stay swappable.
enum TrackSource: String, Codable {
    case spotifyPreview   // 30s preview_url from Spotify Web API
    case soundcloud       // stream URL from SoundCloud API
    case local            // bundled/demo local file
}

struct Track: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var artistName: String
    var albumName: String
    var artworkURL: URL?
    var streamURL: URL?          // playable URL (preview or full, depending on source/rights)
    var duration: TimeInterval   // seconds
    var source: TrackSource

    static func placeholder() -> Track {
        Track(id: UUID().uuidString, title: "Unbekannter Titel", artistName: "Unbekannt",
              albumName: "", artworkURL: nil, streamURL: nil, duration: 0, source: .local)
    }
}

struct Album: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var artistName: String
    var artworkURL: URL?
    var tracks: [Track]
}

struct Artist: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var imageURL: URL?
}

struct RemotePlaylist: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var ownerName: String
    var artworkURL: URL?
    var trackCount: Int
}

struct SearchResults: Codable, Equatable {
    var tracks: [Track] = []
    var artists: [Artist] = []
    var albums: [Album] = []
    var playlists: [RemotePlaylist] = []

    var isEmpty: Bool { tracks.isEmpty && artists.isEmpty && albums.isEmpty && playlists.isEmpty }
}

enum RepeatMode {
    case off, all, one
}
