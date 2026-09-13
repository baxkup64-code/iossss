import Foundation

/// Apple's iTunes Search API — genuinely public: no account, no API key, no
/// registration of any kind. Perfect as a zero-config default so the app
/// works immediately after building, without the user having to set up a
/// Spotify or SoundCloud developer account first.
///
/// Docs: https://performance-partners.apple.com/search-api
/// Endpoint: https://itunes.apple.com/search
enum iTunesAPIClient {

    static func search(query: String) async -> SearchResults {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return SearchResults() }

        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            .init(name: "term", value: query),
            .init(name: "media", value: "music"),
            .init(name: "entity", value: "song"),
            .init(name: "limit", value: "25")
        ]

        do {
            let (data, response) = try await URLSession.shared.data(from: components.url!)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return SearchResults()
            }
            let decoded = try JSONDecoder().decode(iTunesResponse.self, from: data)
            let tracks = decoded.results.compactMap { $0.asTrack }

            // Derive lightweight "album" and "artist" groupings from the same
            // response so Search still has those sections without a second
            // network round-trip.
            var seenAlbums = Set<String>()
            var albums: [Album] = []
            var seenArtists = Set<String>()
            var artists: [Artist] = []

            for item in decoded.results {
                if let collection = item.collectionName, !collection.isEmpty, !seenAlbums.contains(collection) {
                    seenAlbums.insert(collection)
                    albums.append(Album(id: "\(item.collectionId ?? 0)", name: collection,
                                         artistName: item.artistName ?? "Unbekannt",
                                         artworkURL: item.highResArtworkURL, tracks: []))
                }
                if let artist = item.artistName, !seenArtists.contains(artist) {
                    seenArtists.insert(artist)
                    artists.append(Artist(id: "\(item.artistId ?? 0)", name: artist, imageURL: item.highResArtworkURL))
                }
            }

            return SearchResults(tracks: tracks, artists: artists, albums: albums, playlists: [])
        } catch {
            return SearchResults()
        }
    }

    /// A handful of always-available tracks for the Home screen, fetched
    /// live from iTunes so Home isn't empty on first launch either.
    static func trending() async -> [Track] {
        await search(query: "top hits").tracks
    }
}

private struct iTunesResponse: Decodable {
    let results: [iTunesTrack]
}

private struct iTunesTrack: Decodable {
    let trackId: Int?
    let trackName: String?
    let artistName: String?
    let artistId: Int?
    let collectionName: String?
    let collectionId: Int?
    let artworkUrl100: String?
    let previewUrl: String?
    let trackTimeMillis: Int?

    /// iTunes only returns a small 100x100 thumbnail by default; bumping the
    /// path number gives a much higher-resolution image for free.
    var highResArtworkURL: URL? {
        guard let artworkUrl100 else { return nil }
        return URL(string: artworkUrl100.replacingOccurrences(of: "100x100", with: "600x600"))
    }

    var asTrack: Track? {
        guard let trackId, let trackName, let previewUrl else { return nil }
        return Track(id: "itunes-\(trackId)", title: trackName,
                     artistName: artistName ?? "Unbekannt",
                     albumName: collectionName ?? "",
                     artworkURL: highResArtworkURL,
                     streamURL: URL(string: previewUrl),
                     duration: Double(trackTimeMillis ?? 0) / 1000.0,
                     source: .local)
    }
}
