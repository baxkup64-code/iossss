import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

/// Abstraction point for where playback actually comes from. Today it plays
/// preview/allowed stream URLs via AVPlayer; if the official Spotify iOS SDK
/// is added later, a `SpotifySDKPlaybackSource` conforming to this protocol
/// can be swapped in without touching any UI code.
protocol PlaybackSource: AnyObject {
    func load(url: URL) 
    func play()
    func pause()
    func seek(to seconds: TimeInterval)
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
}

/// Owns the `AVPlayer`, the audio session, Now Playing info, and remote
/// command handling. This is the piece responsible for requirements 1–5 in
/// the brief: playback must survive locking the screen, backgrounding the
/// app, and must be controllable from the lock screen / Control Center.
final class AudioPlayerService: NSObject, ObservableObject {

    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isBuffering = false

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemStatusObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?

    var onTrackDidFinish: (() -> Void)?

    override init() {
        super.init()
        configureRemoteCommandCenter()
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification, object: nil)
    }

    // MARK: - Loading & transport

    func load(track: Track, autoplay: Bool = true) {
        guard let url = track.streamURL else { return }
        tearDownCurrentItem()

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        self.player = newPlayer

        itemStatusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.isBuffering = item.status == .unknown
                if item.status == .readyToPlay {
                    self?.duration = item.duration.seconds.isFinite ? item.duration.seconds : track.duration
                    self?.updateNowPlayingInfo(track: track)
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            self?.onTrackDidFinish?()
        }

        addPeriodicTimeObserver()
        updateNowPlayingInfo(track: track)

        if autoplay { play() }
    }

    func play() {
        player?.play()
        isPlaying = true
        MPNowPlayingInfoCenter.default().playbackState = .playing
        updateNowPlayingRate(1.0)
    }

    func pause() {
        player?.pause()
        isPlaying = false
        MPNowPlayingInfoCenter.default().playbackState = .paused
        updateNowPlayingRate(0.0)
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func seek(to seconds: TimeInterval) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = seconds
        updateNowPlayingElapsedTime(seconds)
    }

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds.isFinite ? time.seconds : 0
        }
    }

    private func tearDownCurrentItem() {
        if let token = timeObserverToken { player?.removeTimeObserver(token) }
        timeObserverToken = nil
        itemStatusObservation?.invalidate()
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        player?.pause()
        player = nil
        currentTime = 0
        duration = 0
    }

    // MARK: - MPNowPlayingInfoCenter (Lock Screen / Control Center display)

    private func updateNowPlayingInfo(track: Track) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artistName,
            MPMediaItemPropertyAlbumTitle: track.albumName,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        guard let artworkURL = track.artworkURL else { return }
        URLSession.shared.dataTask(with: artworkURL) { data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            DispatchQueue.main.async {
                info[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
        }.resume()
    }

    private func updateNowPlayingRate(_ rate: Double) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingElapsedTime(_ time: TimeInterval) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - MPRemoteCommandCenter (Lock Screen / Control Center controls)

    var onRemoteNext: (() -> Void)?
    var onRemotePrevious: (() -> Void)?

    private func configureRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.play(); return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause(); return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause(); return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.onRemoteNext?(); return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.onRemotePrevious?(); return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: event.positionTime)
            return .success
        }
    }

    // MARK: - Interruptions & route changes (calls, headphones unplugged, etc.)

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            pause()
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) { play() }
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        // Pause on headphone/AirPlay disconnect, matching standard music-app behavior.
        if reason == .oldDeviceUnavailable {
            pause()
        }
    }

    deinit {
        tearDownCurrentItem()
        NotificationCenter.default.removeObserver(self)
    }
}
