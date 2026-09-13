import SwiftUI

struct PlaylistDetailView: View {
    @Bindable var playlist: PlaylistEntity
    @ObservedObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject private var player: PlayerViewModel
    @State private var isEditing = false
    @State private var showingRename = false
    @State private var newName = ""

    private var sortedEntries: [PlaylistTrackEntity] {
        playlist.tracks.sorted { $0.sortIndex < $1.sortIndex }
    }
    private var tracks: [Track] { sortedEntries.map(\.asTrack) }

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Theme.Color.background)
                    .listRowSeparator(.hidden)
            }

            Section {
                ForEach(sortedEntries, id: \.trackID) { entry in
                    let track = entry.asTrack
                    TrackRow(
                        track: track,
                        isPlaying: player.currentTrack?.id == track.id,
                        isLiked: player.isLiked(track),
                        onTap: { player.play(tracks: tracks, startIndex: tracks.firstIndex(of: track) ?? 0) },
                        onLikeTap: { player.toggleLike(track) }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Theme.Color.background)
                    .listRowSeparator(.hidden)
                }
                .onDelete { indices in
                    for index in indices { libraryViewModel.removeTrack(sortedEntries[index], from: playlist) }
                }
                .onMove { source, destination in
                    libraryViewModel.moveTracks(in: playlist, from: source, to: destination)
                }

                if tracks.isEmpty {
                    Text("Diese Playlist ist noch leer. Füge Songs über die Suche hinzu.")
                        .font(Theme.Font.body())
                        .foregroundStyle(Theme.Color.textSecondary)
                        .listRowBackground(Theme.Color.background)
                        .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Umbenennen") { newName = playlist.name; showingRename = true }
                    EditButton()
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(Theme.Color.textPrimary)
                }
            }
        }
        .alert("Playlist umbenennen", isPresented: $showingRename) {
            TextField("Name", text: $newName)
            Button("Speichern") { libraryViewModel.rename(playlist, to: newName) }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surfaceElevated)
                .frame(width: 180, height: 180)
                .overlay(Text(playlist.coverEmoji).font(.system(size: 72)))
                .padding(.top, Theme.Spacing.md)

            Text(playlist.name).font(Theme.Font.title()).foregroundStyle(Theme.Color.textPrimary)
            Text("\(tracks.count) Songs").font(Theme.Font.caption()).foregroundStyle(Theme.Color.textSecondary)

            if !tracks.isEmpty {
                Button {
                    player.play(tracks: tracks, startIndex: 0)
                } label: {
                    Label("Wiedergabe", systemImage: "play.fill")
                        .font(Theme.Font.subheading())
                        .foregroundStyle(.black)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Color.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressableStyle())
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Theme.Spacing.md)
    }
}
