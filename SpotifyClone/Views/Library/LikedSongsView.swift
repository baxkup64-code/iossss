import SwiftUI
import SwiftData

struct LikedSongsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var player: PlayerViewModel
    @Query(sort: \LikedTrackEntity.likedAt, order: .reverse) private var likedEntities: [LikedTrackEntity]

    private var tracks: [Track] { likedEntities.map(\.asTrack) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(tracks) { track in
                    TrackRow(
                        track: track,
                        isPlaying: player.currentTrack?.id == track.id,
                        isLiked: true,
                        onTap: { player.play(tracks: tracks, startIndex: tracks.firstIndex(of: track) ?? 0) },
                        onLikeTap: { player.toggleLike(track) }
                    )
                }
                if tracks.isEmpty {
                    Text("Noch keine gelikten Songs")
                        .font(Theme.Font.body())
                        .foregroundStyle(Theme.Color.textSecondary)
                        .padding(.top, 60)
                }
            }
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, 120)
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationTitle("Liked Songs")
    }
}
