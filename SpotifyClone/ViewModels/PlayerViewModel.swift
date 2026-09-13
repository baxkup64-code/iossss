import Foundation
import SwiftData
import SwiftUI

@MainActor
final class PlayerViewModel: ObservableObject {

    @Published var queue: [Track] = []
    @Published var currentIndex: Int = 0
    @Published var isShuffled = false
    @Published var repeatMode: RepeatMode = .off
    @Published var isFullPlayerPresented = false
    @Published var likedTrackIDs: Set<String> = []

    let audio = AudioPlayerService()
    private var originalQueueOrder: [Track] = []
    private var modelContext: ModelContext?

    var currentTrack: Track? {
        queue.indices.contains(currentIndex) ? queue[currentIndex] : nil
    }

    init() {
        audio.onTrackDidFinish = { [weak self] in self?.handleTrackFinished() }
        audio.onRemoteNext = { [weak self] in self?.playNext() }
        audio.onRemotePrevious = { [weak self] in self?.playPrevious() }
    }

    func attachModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshLikedIDs()
    }

    // MARK: - Playback control

    /// Starts playback of `tracks` beginning at `startIndex`, replacing the
    /// current queue (e.g. tapping a track in an album or playlist).
    func play(tracks: [Track], startIndex: Int = 0) {
        guard tracks.indices.contains(startIndex) else { return }
        originalQueueOrder = tracks
        queue = isShuffled ? shuffledPreservingCurrent(tracks, keeping: tracks[startIndex]) : tracks
        currentIndex = queue.firstIndex(where: { $0.id == tracks[startIndex].id }) ?? 0
        loadCurrent()
    }

    func playNext() {
        guard !queue.isEmpty else { return }
        if repeatMode == .one {
            audio.seek(to: 0); audio.play(); return
        }
        if currentIndex + 1 < queue.count {
            currentIndex += 1
            loadCurrent()
        } else if repeatMode == .all {
            currentIndex = 0
            loadCurrent()
        } else {
            audio.pause()
        }
    }

    func playPrevious() {
        guard !queue.isEmpty else { return }
        // Standard music-app behavior: restart the track if more than 3s in,
        // otherwise go to the previous track.
        if audio.currentTime > 3 {
            audio.seek(to: 0)
            return
        }
        if currentIndex > 0 {
            currentIndex -= 1
            loadCurrent()
        } else {
            audio.seek(to: 0)
        }
    }

    func togglePlayPause() { audio.togglePlayPause() }

    func toggleShuffle() {
        isShuffled.toggle()
        guard let current = currentTrack else { return }
        Theme.Haptics.selection()
        if isShuffled {
            queue = shuffledPreservingCurrent(originalQueueOrder, keeping: current)
        } else {
            queue = originalQueueOrder
        }
        currentIndex = queue.firstIndex(where: { $0.id == current.id }) ?? 0
    }

    func cycleRepeatMode() {
        Theme.Haptics.selection()
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    func playTrackInQueue(at index: Int) {
        guard queue.indices.contains(index) else { return }
        currentIndex = index
        loadCurrent()
    }

    private func loadCurrent() {
        guard let track = currentTrack else { return }
        audio.load(track: track)
    }

    private func handleTrackFinished() {
        playNext()
    }

    private func shuffledPreservingCurrent(_ tracks: [Track], keeping current: Track) -> [Track] {
        var rest = tracks.filter { $0.id != current.id }
        rest.shuffle()
        return [current] + rest
    }

    // MARK: - Likes (SwiftData)

    func isLiked(_ track: Track) -> Bool { likedTrackIDs.contains(track.id) }

    func toggleLike(_ track: Track) {
        guard let modelContext else { return }
        Theme.Haptics.light()
        if isLiked(track) {
            let id = track.id
            let descriptor = FetchDescriptor<LikedTrackEntity>(predicate: #Predicate { $0.trackID == id })
            if let existing = try? modelContext.fetch(descriptor).first {
                modelContext.delete(existing)
            }
            likedTrackIDs.remove(track.id)
        } else {
            modelContext.insert(LikedTrackEntity(track: track))
            likedTrackIDs.insert(track.id)
        }
        try? modelContext.save()
    }

    private func refreshLikedIDs() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<LikedTrackEntity>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        likedTrackIDs = Set(all.map(\.trackID))
    }
}
