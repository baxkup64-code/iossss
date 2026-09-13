import SwiftUI

struct QueueView: View {
    @EnvironmentObject private var player: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let current = player.currentTrack {
                    Section("Wird abgespielt") {
                        TrackRow(track: current, isPlaying: true, onTap: {})
                            .listRowBackground(Theme.Color.background)
                    }
                }

                Section("Als Nächstes") {
                    ForEach(Array(player.queue.enumerated()).filter { $0.offset > player.currentIndex }, id: \.element.id) { pair in
                        TrackRow(track: pair.element, onTap: {
                            player.playTrackInQueue(at: pair.offset)
                        })
                        .listRowBackground(Theme.Color.background)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.Color.background.ignoresSafeArea())
            .navigationTitle("Warteschlange")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
