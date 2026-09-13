import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var player: PlayerViewModel

    private let greetingColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    greeting

                    quickPicksGrid

                    SectionHeader(title: "Zuletzt gehört")
                    horizontalTrackRow(viewModel.recentlyPlayed)

                    SectionHeader(title: "Für dich gemacht")
                    horizontalTrackRow(viewModel.madeForYou)
                }
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, 120) // room for mini player
            }
            .background(Theme.Color.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Color.background, for: .navigationBar)
            .task { await viewModel.load() }
        }
    }

    private var greeting: some View {
        Text(greetingText())
            .font(Theme.Font.title())
            .foregroundStyle(Theme.Color.textPrimary)
            .padding(.horizontal, Theme.Spacing.md)
    }

    private var quickPicksGrid: some View {
        LazyVGrid(columns: greetingColumns, spacing: Theme.Spacing.sm) {
            ForEach(viewModel.recentlyPlayed.prefix(4)) { track in
                Button {
                    player.play(tracks: viewModel.recentlyPlayed, startIndex: viewModel.recentlyPlayed.firstIndex(of: track) ?? 0)
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        ArtworkView(url: track.artworkURL, cornerRadius: 4)
                            .frame(width: 56, height: 56)
                        Text(track.title)
                            .font(Theme.Font.subheading())
                            .foregroundStyle(Theme.Color.textPrimary)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }
                    .background(Theme.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(PressableStyle(scale: 0.98))
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func horizontalTrackRow(_ tracks: [Track]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                ForEach(tracks) { track in
                    TrackCard(track: track) {
                        Theme.Haptics.light()
                        player.play(tracks: tracks, startIndex: tracks.firstIndex(of: track) ?? 0)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Guten Morgen"
        case 12..<18: return "Guten Tag"
        default: return "Guten Abend"
        }
    }
}
