import Foundation
import SwiftData

/// A user-created, purely local playlist. No account, no server sync —
/// everything lives in the on-device SwiftData store.
@Model
final class PlaylistEntity {
    @Attribute(.unique) var id: String
    var name: String
    var createdAt: Date
    var coverEmoji: String   // simple own-made "cover" instead of any copied artwork
    @Relationship(deleteRule: .cascade, inverse: \PlaylistTrackEntity.playlist)
    var tracks: [PlaylistTrackEntity] = []

    init(id: String = UUID().uuidString, name: String, coverEmoji: String = "🎵") {
        self.id = id
        self.name = name
        self.createdAt = .now
        self.coverEmoji = coverEmoji
    }
}

/// A track saved inside a local playlist. Stores just enough info to render
/// and re-play the track without needing a live network round-trip, plus a
/// `sortIndex` so the user can freely reorder songs.
@Model
final class PlaylistTrackEntity {
    var trackID: String
    var title: String
    var artistName: String
    var albumName: String
    var artworkURLString: String?
    var streamURLString: String?
    var duration: TimeInterval
    var sourceRaw: String
    var sortIndex: Int
    var playlist: PlaylistEntity?

    init(track: Track, sortIndex: Int) {
        self.trackID = track.id
        self.title = track.title
        self.artistName = track.artistName
        self.albumName = track.albumName
        self.artworkURLString = track.artworkURL?.absoluteString
        self.streamURLString = track.streamURL?.absoluteString
        self.duration = track.duration
        self.sourceRaw = track.source.rawValue
        self.sortIndex = sortIndex
    }

    var asTrack: Track {
        Track(id: trackID, title: title, artistName: artistName, albumName: albumName,
              artworkURL: artworkURLString.flatMap(URL.init(string:)),
              streamURL: streamURLString.flatMap(URL.init(string:)),
              duration: duration,
              source: TrackSource(rawValue: sourceRaw) ?? .local)
    }
}

/// "Liked Songs" — Spotify's most-used implicit playlist, reimplemented as
/// its own simple local table.
@Model
final class LikedTrackEntity {
    @Attribute(.unique) var trackID: String
    var title: String
    var artistName: String
    var albumName: String
    var artworkURLString: String?
    var streamURLString: String?
    var duration: TimeInterval
    var sourceRaw: String
    var likedAt: Date

    init(track: Track) {
        self.trackID = track.id
        self.title = track.title
        self.artistName = track.artistName
        self.albumName = track.albumName
        self.artworkURLString = track.artworkURL?.absoluteString
        self.streamURLString = track.streamURL?.absoluteString
        self.duration = track.duration
        self.sourceRaw = track.source.rawValue
        self.likedAt = .now
    }

    var asTrack: Track {
        Track(id: trackID, title: title, artistName: artistName, albumName: albumName,
              artworkURL: artworkURLString.flatMap(URL.init(string:)),
              streamURL: streamURLString.flatMap(URL.init(string:)),
              duration: duration,
              source: TrackSource(rawValue: sourceRaw) ?? .local)
    }
}
