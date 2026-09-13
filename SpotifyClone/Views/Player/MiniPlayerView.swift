import SwiftUI

struct MiniPlayerView: View {
    var namespace: Namespace.ID
    @EnvironmentObject private var player: PlayerViewModel
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        guard let track = player.currentTrack else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(spacing: 0) {
                progressBar

                HStack(spacing: Theme.Spacing.sm) {
                    ArtworkView(url: track.artworkURL, cornerRadius: 6)
                        .frame(width: 44, height: 44)
                        .matchedGeometryEffect(id: "artwork", in: namespace)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(track.title).font(Theme.Font.subheading()).foregroundStyle(Theme.Color.textPrimary).lineLimit(1)
                        Text(track.artistName).font(Theme.Font.caption()).foregroundStyle(Theme.Color.textSecondary).lineLimit(1)
                    }

                    Spacer()

                    Button(action: { player.toggleLike(track) }) {
                        Image(systemName: player.isLiked(track) ? "heart.fill" : "heart")
                            .foregroundStyle(player.isLiked(track) ? Theme.Color.accent : Theme.Color.textPrimary)
                    }
                    .buttonStyle(PressableStyle())

                    Button(action: { Theme.Haptics.medium(); player.togglePlayPause() }) {
                        Image(systemName: player.audio.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.Color.textPrimary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PressableStyle())
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
            .background(.ultraThinMaterial)
            .background(Theme.Color.surfaceElevated.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, Theme.Spacing.sm)
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = min(0, value.translation.height)
                    }
                    .onEnded { value in
                        if value.translation.height < -40 {
                            Theme.Haptics.light()
                            player.isFullPlayerPresented = true
                        }
                    }
            )
            .onTapGesture {
                Theme.Haptics.light()
                player.isFullPlayerPresented = true
            }
        )
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let progress = player.audio.duration > 0 ? player.audio.currentTime / player.audio.duration : 0
            Rectangle()
                .fill(Theme.Color.accent)
                .frame(width: geo.size.width * progress, height: 2)
        }
        .frame(height: 2)
    }
}
