import SwiftUI

/// Cached async artwork with a soft placeholder — avoids the "flash of gray
/// box" feel and gives the premium look the brief asks for.
struct ArtworkView: View {
    let url: URL?
    var cornerRadius: CGFloat = Theme.Radius.card

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                placeholder
            case .empty:
                placeholder.overlay(ProgressView().tint(.white.opacity(0.6)))
            @unknown default:
                placeholder
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Theme.Color.surfaceElevated)
            .overlay(Image(systemName: "music.note").foregroundStyle(Theme.Color.textTertiary))
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title).font(Theme.Font.heading()).foregroundStyle(Theme.Color.textPrimary)
            Spacer()
            if let actionTitle {
                Button(actionTitle, action: { action?() })
                    .font(Theme.Font.caption())
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

/// Horizontally scrolling card used across Home for "Recently played",
/// "Made for you", etc.
struct TrackCard: View {
    let track: Track
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ArtworkView(url: track.artworkURL)
                    .frame(width: 140, height: 140)
                Text(track.title)
                    .font(Theme.Font.subheading())
                    .foregroundStyle(Theme.Color.textPrimary)
                    .lineLimit(1)
                Text(track.artistName)
                    .font(Theme.Font.caption())
                    .foregroundStyle(Theme.Color.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 140)
        }
        .buttonStyle(PressableStyle())
    }
}

/// Standard row used in Search results, playlist detail, and Library lists.
struct TrackRow: View {
    let track: Track
    var isPlaying: Bool = false
    var isLiked: Bool = false
    var onTap: () -> Void
    var onLikeTap: (() -> Void)? = nil
    var onMoreTap: (() -> Void)? = nil

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                ArtworkView(url: track.artworkURL, cornerRadius: 6)
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(Theme.Font.subheading())
                        .foregroundStyle(isPlaying ? Theme.Color.accent : Theme.Color.textPrimary)
                        .lineLimit(1)
                    Text(track.artistName)
                        .font(Theme.Font.caption())
                        .foregroundStyle(Theme.Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if let onLikeTap {
                    Button(action: onLikeTap) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? Theme.Color.accent : Theme.Color.textSecondary)
                    }
                    .buttonStyle(PressableStyle())
                }
                if let onMoreTap {
                    Button(action: onMoreTap) {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Simple animated equalizer glyph shown next to the currently-playing track.
struct PlayingIndicator: View {
    @State private var animate = false
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(Theme.Color.accent)
                    .frame(width: 3, height: animate ? CGFloat.random(in: 6...16) : 4)
                    .animation(
                        .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15),
                        value: animate)
            }
        }
        .frame(height: 16)
        .onAppear { animate = true }
    }
}
