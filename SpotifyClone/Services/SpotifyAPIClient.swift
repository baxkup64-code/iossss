import Foundation

/// Thin wrapper around the official Spotify Web API.
///
/// Important scope note: the Web API's Client Credentials flow (used here)
/// only grants access to public catalog data — search, track/album/artist
/// metadata, and (where available) a 30-second `preview_url`. It does **not**
/// grant rights to stream full tracks; full-track playback in a third-party
/// app requires the official Spotify iOS SDK with an authenticated Premium
/// user, which is a separate integration (see README). This client therefore
/// only ever exposes preview URLs for playback, which is within Spotify's
/// terms for this kind of integration.
actor SpotifyAPIClient {
    static let shared = SpotifyAPIClient()

    private var accessToken: String?
    private var tokenExpiry: Date = .distantPast

    private func validToken() async throws -> String {
        if let token = accessToken, Date() < tokenExpiry {
            return token
        }
        return try await fetchNewToken()
    }

    private func fetchNewToken() async throws -> String {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let credentials = "\(APIConfig.spotifyClientID):\(APIConfig.spotifyClientSecret)"
        let basicAuth = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(basicAuth)", forHTTPHeaderField: "Authorization")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.authFailed
        }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = decoded.access_token
        tokenExpiry = Date().addingTimeInterval(TimeInterval(decoded.expires_in - 30))
        return decoded.access_token
    }

    func search(query: String) async throws -> SearchResults {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return SearchResults() }
        let token = try await validToken()

        var components = URLComponents(string: "https://api.spotify.com/v1/search")!
        components.queryItems = [
            .init(name: "q", value: query),
            .init(name: "type", value: "track,artist,album,playlist"),
            .init(name: "limit", value: "15")
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.requestFailed
        }
        let decoded = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
        return decoded.asSearchResults
    }

    enum APIError: Error { case authFailed, requestFailed }

    private struct TokenResponse: Decodable {
        let access_token: String
        let expires_in: Int
    }
}

// MARK: - Spotify JSON response shapes

private struct SpotifySearchResponse: Decodable {
    struct Paging<T: Decodable>: Decodable { let items: [T] }

    let tracks: Paging<SpotifyTrack>?
    let artists: Paging<SpotifyArtist>?
    let albums: Paging<SpotifyAlbum>?
    let playlists: Paging<SpotifyPlaylist>?

    var asSearchResults: SearchResults {
        SearchResults(
            tracks: tracks?.items.compactMap { $0.asTrack } ?? [],
            artists: artists?.items.map { $0.asArtist } ?? [],
            albums: albums?.items.map { $0.asAlbum } ?? [],
            playlists: playlists?.items.compactMap { $0.asRemotePlaylist } ?? []
        )
    }
}

private struct SpotifyImage: Decodable { let url: String }

private struct SpotifyArtistRef: Decodable { let name: String }

private struct SpotifyAlbumRef: Decodable {
    let name: String
    let images: [SpotifyImage]
}

private struct SpotifyTrack: Decodable {
    let id: String
    let name: String
    let artists: [SpotifyArtistRef]
    let album: SpotifyAlbumRef
    let duration_ms: Int
    let preview_url: String?

    var asTrack: Track? {
        Track(id: id, title: name,
              artistName: artists.first?.name ?? "Unbekannt",
              albumName: album.name,
              artworkURL: album.images.first.flatMap { URL(string: $0.url) },
              streamURL: preview_url.flatMap(URL.init(string:)),
              duration: Double(duration_ms) / 1000.0,
              source: .spotifyPreview)
    }
}

private struct SpotifyArtist: Decodable {
    let id: String
    let name: String
    let images: [SpotifyImage]

    var asArtist: Artist {
        Artist(id: id, name: name, imageURL: images.first.flatMap { URL(string: $0.url) })
    }
}

private struct SpotifyAlbum: Decodable {
    let id: String
    let name: String
    let artists: [SpotifyArtistRef]
    let images: [SpotifyImage]

    var asAlbum: Album {
        Album(id: id, name: name, artistName: artists.first?.name ?? "Unbekannt",
              artworkURL: images.first.flatMap { URL(string: $0.url) }, tracks: [])
    }
}

private struct SpotifyPlaylist: Decodable {
    struct Owner: Decodable { let display_name: String? }
    struct Tracks: Decodable { let total: Int }
    let id: String?
    let name: String?
    let owner: Owner?
    let images: [SpotifyImage]?
    let tracks: Tracks?

    var asRemotePlaylist: RemotePlaylist? {
        guard let id, let name else { return nil }
        return RemotePlaylist(id: id, name: name, ownerName: owner?.display_name ?? "Spotify",
                               artworkURL: images?.first.flatMap { URL(string: $0.url) },
                               trackCount: tracks?.total ?? 0)
    }
}
