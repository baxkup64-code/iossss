import Foundation

/// Combines all backends behind one simple interface for the ViewModels.
///
/// iTunes is the always-on, zero-config default (no signup needed at all),
/// so the app is fully usable — search, artwork, playable previews — right
/// after building it, without touching `APIConfig.swift`. Spotify and
/// SoundCloud results are added on top automatically the moment real
/// credentials are entered there; until then they're simply skipped.
final class MusicAPIService {
    static let shared = MusicAPIService()

    func search(query: String) async -> SearchResults {
        async let iTunesResults = iTunesAPIClient.search(query: query)

        let spotifyConfigured = APIConfig.spotifyClientID != "YOUR_SPOTIFY_CLIENT_ID"
        let soundCloudConfigured = APIConfig.soundCloudClientID != "YOUR_SOUNDCLOUD_CLIENT_ID"

        async let spotifyResults: SearchResults = spotifyConfigured
            ? ((try? await SpotifyAPIClient.shared.search(query: query)) ?? SearchResults())
            : SearchResults()
        async let soundcloudTracks: [Track] = soundCloudConfigured
            ? ((try? await SoundCloudAPIClient.shared.search(query: query)) ?? [])
            : []

        var combined = await iTunesResults
        let spotify = await spotifyResults
        combined.tracks.append(contentsOf: spotify.tracks)
        combined.artists.append(contentsOf: spotify.artists)
        combined.albums.append(contentsOf: spotify.albums)
        combined.playlists.append(contentsOf: spotify.playlists)
        combined.tracks.append(contentsOf: await soundcloudTracks)
        return combined
    }

    /// Live, always-available Home content — no API key required.
    func trendingHomeTracks() async -> [Track] {
        await iTunesAPIClient.trending()
    }

    /// Small built-in fallback in case the network is unreachable, so Home
    /// never appears completely empty.
    func sampleHomeTracks() -> [Track] {
        [
            Track(id: "demo-1", title: "Morning Drive", artistName: "Ambient Collective", albumName: "Sunrise Sessions",
                  artworkURL: URL(string: "https://picsum.photos/seed/morning/400"),
                  streamURL: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
                  duration: 320, source: .local),
            Track(id: "demo-2", title: "Night Pulse", artistName: "Neon Skyline", albumName: "City Lights",
                  artworkURL: URL(string: "https://picsum.photos/seed/night/400"),
                  streamURL: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"),
                  duration: 245, source: .local),
            Track(id: "demo-3", title: "Analog Waves", artistName: "Retro Circuit", albumName: "Waveforms",
                  artworkURL: URL(string: "https://picsum.photos/seed/waves/400"),
                  streamURL: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"),
                  duration: 290, source: .local),
            Track(id: "demo-4", title: "Golden Hour", artistName: "Ambient Collective", albumName: "Sunrise Sessions",
                  artworkURL: URL(string: "https://picsum.photos/seed/golden/400"),
                  streamURL: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3"),
                  duration: 210, source: .local)
        ]
    }
}
