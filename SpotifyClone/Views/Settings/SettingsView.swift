import SwiftUI

struct SettingsView: View {
    @AppStorage("streamingQuality") private var streamingQuality = "Normal"
    @AppStorage("downloadOverWifiOnly") private var wifiOnly = true
    private let qualities = ["Niedrig", "Normal", "Hoch"]

    var body: some View {
        NavigationStack {
            List {
                Section("Wiedergabe") {
                    Picker("Streaming-Qualität", selection: $streamingQuality) {
                        ForEach(qualities, id: \.self) { Text($0) }
                    }
                    Toggle("Nur über WLAN herunterladen", isOn: $wifiOnly)
                }

                Section("Musikquellen") {
                    LabeledContent("iTunes (Vorschauen)", value: "Aktiv – kein Login nötig")
                    LabeledContent("Spotify", value: APIConfig.spotifyClientID == "YOUR_SPOTIFY_CLIENT_ID" ? "Nicht konfiguriert (optional)" : "Verbunden")
                    LabeledContent("SoundCloud", value: APIConfig.soundCloudClientID == "YOUR_SOUNDCLOUD_CLIENT_ID" ? "Nicht konfiguriert (optional)" : "Verbunden")
                }

                Section("Über") {
                    LabeledContent("Version", value: "1.0.0")
                    Text("Diese App nutzt ausschließlich offizielle APIs und lokale Speicherung. Es gibt kein Nutzerkonto und keine Cloud-Synchronisierung.")
                        .font(Theme.Font.caption())
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Color.background.ignoresSafeArea())
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
