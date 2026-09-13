import SwiftUI

struct RootView: View {
    @EnvironmentObject private var player: PlayerViewModel
    @Namespace private var playerNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }

                SearchView()
                    .tabItem { Label("Suchen", systemImage: "magnifyingglass") }

                LibraryView()
                    .tabItem { Label("Mediathek", systemImage: "books.vertical.fill") }

                SettingsView()
                    .tabItem { Label("Einstellungen", systemImage: "gearshape.fill") }
            }
            .tint(Theme.Color.accent)

            if player.currentTrack != nil && !player.isFullPlayerPresented {
                MiniPlayerView(namespace: playerNamespace)
                    .padding(.bottom, 49) // sits just above the tab bar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(Theme.Animation.spring, value: player.currentTrack?.id)
        .fullScreenCover(isPresented: $player.isFullPlayerPresented) {
            FullPlayerView(namespace: playerNamespace)
        }
    }
}
