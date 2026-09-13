import SwiftUI
import SwiftData
import AVFoundation

@main
struct SpotifyCloneApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var player = PlayerViewModel()

    let modelContainer: ModelContainer = {
        let schema = Schema([PlaylistEntity.self, PlaylistTrackEntity.self, LikedTrackEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(player)
                .preferredColorScheme(.dark)
                .modelContainer(modelContainer)
                .onAppear { player.attachModelContext(modelContainer.mainContext) }
        }
    }
}

/// Handles global app lifecycle concerns: audio session category + activation.
/// Configuring the session for `.playback` is what allows audio to continue
/// after the screen locks or the app moves to the background.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureAudioSession()
        return true
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // `.playback` + `.default` mode is the standard configuration for a
            // music app: it keeps playing with the screen locked, silences the
            // silent-switch, and supports background audio + Bluetooth/AirPlay.
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }
    }
}
