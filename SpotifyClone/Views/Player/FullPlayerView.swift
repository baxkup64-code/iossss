import SwiftUI

struct FullPlayerView: View {
    var namespace: Namespace.ID
    @EnvironmentObject private var player: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isDraggingSeek = false
    @State private var seekValue: Double = 0
    @State private var showingQueue = false
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        guard let track = player.currentTrack else { return AnyView(EmptyView()) }

        return AnyView(
            ZStack {
                backgroundGradient(for: track)

                VStack(spacing: Theme.Spacing.lg) {
                    grabberAndHeader

                    Spacer(minLength: 0)

                    ArtworkView(url: track.artworkURL, cornerRadius: 16)
                        .matchedGeometryEffect(id: "artwork", in: namespace)
                        .frame(width: 320, height: 320)
                        .shadow(color: .black.opacity(0.4), radius: 30, y: 20)
                        .scaleEffect(player.audio.isPlaying ? 1.0 : 0.94)
                        .animation(Theme.Animation.spring, value: player.audio.isPlaying)

                    trackInfo(track)

                    seekSection

                    transportControls

                    bottomRow(track)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)
            }
            .offset(y: max(0, dragOffset.height))
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        if value.translation.height > 120 {
                            dismiss()
                        }
                    }
            )
            .sheet(isPresented: $showingQueue) { QueueView() }
        )
    }

    private func backgroundGradient(for track: Track) -> some View {
        LinearGradient(
            colors: [Theme.Color.surfaceElevated, Theme.Color.background],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var grabberAndHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            Capsule().fill(Theme.Color.textTertiary).frame(width: 36, height: 5)
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.down").font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                }
                Spacer()
                Text("Wird abgespielt").font(Theme.Font.caption()).foregroundStyle(Theme.Color.textSecondary)
                Spacer()
                Button(action: { showingQueue = true }) {
                    Image(systemName: "list.bullet").foregroundStyle(Theme.Color.textPrimary)
                }
            }
        }
    }

    private func trackInfo(_ track: Track) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title).font(Theme.Font.heading()).foregroundStyle(Theme.Color.textPrimary).lineLimit(1)
                Text(track.artistName).font(Theme.Font.body()).foregroundStyle(Theme.Color.textSecondary).lineLimit(1)
            }
            Spacer()
            Button(action: { player.toggleLike(track) }) {
                Image(systemName: player.isLiked(track) ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundStyle(player.isLiked(track) ? Theme.Color.accent : Theme.Color.textPrimary)
            }
            .buttonStyle(PressableStyle())
        }
    }

    private var seekSection: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { isDraggingSeek ? seekValue : player.audio.currentTime },
                    set: { seekValue = $0 }
                ),
                in: 0...(max(player.audio.duration, 1)),
                onEditingChanged: { editing in
                    isDraggingSeek = editing
                    if !editing { player.audio.seek(to: seekValue) }
                }
            )
            .tint(Theme.Color.accent)

            HStack {
                Text(formatted(isDraggingSeek ? seekValue : player.audio.currentTime))
                Spacer()
                Text(formatted(player.audio.duration))
            }
            .font(Theme.Font.caption())
            .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    private var transportControls: some View {
        HStack(spacing: Theme.Spacing.xl) {
            Button(action: { player.toggleShuffle() }) {
                Image(systemName: "shuffle")
                    .foregroundStyle(player.isShuffled ? Theme.Color.accent : Theme.Color.textSecondary)
            }

            Button(action: { Theme.Haptics.light(); player.playPrevious() }) {
                Image(systemName: "backward.fill").font(.system(size: 26)).foregroundStyle(Theme.Color.textPrimary)
            }

            Button(action: { Theme.Haptics.medium(); player.togglePlayPause() }) {
                Image(systemName: player.audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.black)
                    .frame(width: 68, height: 68)
                    .background(Theme.Color.textPrimary)
                    .clipShape(Circle())
            }
            .buttonStyle(PressableStyle())

            Button(action: { Theme.Haptics.light(); player.playNext() }) {
                Image(systemName: "forward.fill").font(.system(size: 26)).foregroundStyle(Theme.Color.textPrimary)
            }

            Button(action: { player.cycleRepeatMode() }) {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                    .foregroundStyle(player.repeatMode == .off ? Theme.Color.textSecondary : Theme.Color.accent)
            }
        }
        .font(.system(size: 20))
    }

    private func bottomRow(_ track: Track) -> some View {
        HStack {
            Image(systemName: "iphone.and.arrow.forward").foregroundStyle(Theme.Color.textSecondary)
            Spacer()
            Text(sourceLabel(for: track)).font(Theme.Font.caption()).foregroundStyle(Theme.Color.textTertiary)
            Spacer()
            Image(systemName: "airplayaudio").foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(.top, Theme.Spacing.sm)
    }

    private func sourceLabel(for track: Track) -> String {
        switch track.source {
        case .spotifyPreview: return "Vorschau · Spotify"
        case .soundcloud: return "SoundCloud"
        case .local: return "Demo"
        }
    }

    private func formatted(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
