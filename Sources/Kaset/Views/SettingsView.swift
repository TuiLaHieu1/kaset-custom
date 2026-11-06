import SwiftUI

// MARK: - SettingsView

/// Main settings view with tabbed navigation.
struct SettingsView: View {
    @Environment(UpdaterService.self) private var updaterService
    @Environment(ScrobblingCoordinator.self) private var scrobblingCoordinator
    @State private var settings = SettingsManager.shared

    var body: some View {
        TabView {
            GeneralSettingsView(updaterService: self.updaterService)
                .tabItem {
                    Label(String(localized: "General"), systemImage: "gearshape")
                }

            MusicSettingsView()
                .tabItem {
                    Label(String(localized: "Music"), systemImage: "music.note")
                }

            YouTubeSettingsView()
                .tabItem {
                    Label(String(localized: "YouTube"), systemImage: "play.rectangle.fill")
                }

            EqualizerSettingsView()
                .tabItem {
                    Label(String(localized: "Equalizer"), systemImage: "slider.vertical.3")
                }

            ScrobblingSettingsView()
                .environment(self.scrobblingCoordinator)
                .tabItem {
                    Label(String(localized: "Scrobbling"), systemImage: "music.note.list")
                }

            // Conditionally rendered (Apple Intelligence is macOS 26+ and
            // hidden in legacy UI mode). Placed near the end so that when it is
            // absent, only the trailing Extensions tab shifts — the stable core
            // tabs (General…Scrobbling) keep their positions.
            if !self.settings.useLegacyMacOS15UI, #available(macOS 26.0, *) {
                IntelligenceSettingsView()
                    .tabItem {
                        Label(String(localized: "Intelligence"), systemImage: "sparkles")
                    }
            }

            ExtensionsSettingsView()
                .tabItem {
                    Label(String(localized: "Extensions"), systemImage: "puzzlepiece.extension")
                }
        }
        // 520×520 fits the Equalizer tab's six-band slider grid + curve
        // preview; the other tabs grow comfortably into the extra space.
        .frame(width: 520, height: 520)
    }
}
