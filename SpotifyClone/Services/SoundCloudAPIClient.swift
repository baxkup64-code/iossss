import Foundation

/// Wrapper around the official SoundCloud API. SoundCloud's public API can
/// expose a `stream_url` for tracks that the uploader has explicitly marked
/// as streamable, which is the only playback this client ever uses — no
/// scraping, no bypassing of tracks that are marked non-streamable/private.
actor SoundCloudAPIClient {
    static let shared = SoundCloudAPIClient()

    func search(query: String) async throws -> [Track] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        var components = URLComponents(string: "https://api.soundcloud.com/tracks")!
        components.queryItems = [
            .init(name: "q", value: query),
            .init(name: "client_id", value: APIConfig.soundCloudClientID),
            .init(name: "limit", value: "15")
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.requestFailed
        }
        let decoded = try JSONDecoder().decode([SoundCloudTrack].self, from: data)
        return decoded.compactMap { $0.asTrack }
    }

    enum APIError: Error { case requestFailed }
}

private struct SoundCloudTrack: Decodable {
    let id: Int
    let title: String
    let user: User?
    let artwork_url: String?
    let duration: Int?
    let streamable: Bool?
    let stream_url: String?

    struct User: Decodable { let username: String }

    var asTrack: Track? {
        guard streamable == true, let streamURLString = stream_url else { return nil }
        // Append client_id, as required by SoundCloud for authenticated stream requests.
        let fullStreamURLString = "\(streamURLString)?client_id=\(APIConfig.soundCloudClientID)"
        return Track(id: String(id), title: title,
                     artistName: user?.username ?? "Unbekannt",
                     albumName: "",
                     artworkURL: artwork_url.flatMap { URL(string: $0.replacingOccurrences(of: "-large", with: "-t500x500")) },
                     streamURL: URL(string: fullStreamURLString),
                     duration: Double(duration ?? 0) / 1000.0,
                     source: .soundcloud)
    }
}
