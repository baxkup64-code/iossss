import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var player: PlayerViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    filterPills

                    if viewModel.query.isEmpty {
                        emptyState
                    } else if viewModel.isSearching {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                    } else if viewModel.results.isEmpty {
                        noResultsState
                    } else {
                        resultsList
                    }
                }
                .padding(.bottom, 120)
            }
            .background(Theme.Color.background.ignoresSafeArea())
            .navigationTitle("Suchen")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Songs, Künstler, Alben")
        }
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(SearchViewModel.Filter.allCases) { filter in
                    let isActive = viewModel.activeFilter == filter
                    Button {
                        Theme.Haptics.selection()
                        withAnimation(Theme.Animation.easeFast) { viewModel.activeFilter = filter }
                    } label: {
                        Text(filter.rawValue)
                            .font(Theme.Font.caption())
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(isActive ? Theme.Color.accent : Theme.Color.surface)
                            .foregroundStyle(isActive ? Color.black : Theme.Color.textPrimary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    @ViewBuilder
    private var resultsList: some View {
        let filter = viewModel.activeFilter

        if filter == .all || filter == .songs {
            if !viewModel.results.tracks.isEmpty {
                SectionHeader(title: "Songs")
                VStack(spacing: 0) {
                    ForEach(viewModel.results.tracks) { track in
                        TrackRow(
                            track: track,
                            isPlaying: player.currentTrack?.id == track.id,
                            isLiked: player.isLiked(track),
                            onTap: {
                                player.play(tracks: viewModel.results.tracks,
                                            startIndex: viewModel.results.tracks.firstIndex(of: track) ?? 0)
                            },
                            onLikeTap: { player.toggleLike(track) }
                        )
                    }
                }
            }
        }

        if filter == .all || filter == .artists {
            if !viewModel.results.artists.isEmpty {
                SectionHeader(title: "Künstler")
                artistRow
            }
        }

        if filter == .all || filter == .albums {
            if !viewModel.results.albums.isEmpty {
                SectionHeader(title: "Alben")
                albumRow
            }
        }

        if filter == .all || filter == .playlists {
            if !viewModel.results.playlists.isEmpty {
                SectionHeader(title: "Playlists")
                playlistRow
            }
        }
    }

    private var artistRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.results.artists) { artist in
                    VStack(spacing: Theme.Spacing.xs) {
                        ArtworkView(url: artist.imageURL, cornerRadius: 70)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        Text(artist.name).font(Theme.Font.caption()).foregroundStyle(Theme.Color.textPrimary).lineLimit(1)
                    }.frame(width: 100)
                }
            }.padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var albumRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.results.albums) { album in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        ArtworkView(url: album.artworkURL).frame(width: 140, height: 140)
                        Text(album.name).font(Theme.Font.subheading()).foregroundStyle(Theme.Color.textPrimary).lineLimit(1)
                        Text(album.artistName).font(Theme.Font.caption()).foregroundStyle(Theme.Color.textSecondary).lineLimit(1)
                    }.frame(width: 140)
                }
            }.padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var playlistRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.results.playlists) { playlist in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        ArtworkView(url: playlist.artworkURL).frame(width: 140, height: 140)
                        Text(playlist.name).font(Theme.Font.subheading()).foregroundStyle(Theme.Color.textPrimary).lineLimit(1)
                        Text("Von \(playlist.ownerName)").font(Theme.Font.caption()).foregroundStyle(Theme.Color.textSecondary).lineLimit(1)
                    }.frame(width: 140)
                }
            }.padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass").font(.system(size: 40)).foregroundStyle(Theme.Color.textTertiary)
            Text("Suche nach Songs, Künstlern oder Alben").font(Theme.Font.body()).foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.top, 80)
    }

    private var noResultsState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "questionmark.circle").font(.system(size: 40)).foregroundStyle(Theme.Color.textTertiary)
            Text("Keine Ergebnisse gefunden").font(Theme.Font.body()).foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.top, 80)
    }
}
