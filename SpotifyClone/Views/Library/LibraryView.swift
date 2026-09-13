import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showingCreatePlaylist = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    NavigationLink(destination: LikedSongsView()) {
                        LibraryRow(emoji: "💚", title: "Liked Songs",
                                   subtitle: "\(viewModel.likedSongsCount) Songs")
                    }

                    ForEach(viewModel.playlists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist, libraryViewModel: viewModel)) {
                            LibraryRow(emoji: playlist.coverEmoji, title: playlist.name,
                                       subtitle: "Playlist · \(playlist.tracks.count) Songs")
                        }
                    }
                    .onDelete { indices in
                        for index in indices { viewModel.deletePlaylist(viewModel.playlists[index]) }
                    }
                }
                .padding(Theme.Spacing.md)
                .padding(.bottom, 120)
            }
            .background(Theme.Color.background.ignoresSafeArea())
            .navigationTitle("Mediathek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePlaylist = true }) {
                        Image(systemName: "plus").foregroundStyle(Theme.Color.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlaylist) {
                CreatePlaylistView(libraryViewModel: viewModel)
            }
            .onAppear { viewModel.attach(modelContext) }
        }
    }
}

private struct LibraryRow: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surfaceElevated)
                .frame(width: 56, height: 56)
                .overlay(Text(emoji).font(.system(size: 26)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Font.subheading()).foregroundStyle(Theme.Color.textPrimary)
                Text(subtitle).font(Theme.Font.caption()).foregroundStyle(Theme.Color.textSecondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}
