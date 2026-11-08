import AppKit
import SwiftUI

/// Presentation actions shared by the playback menu for the active source.
@MainActor
struct PlayerPresentationCommands {
    let settings: SettingsManager
    let playerService: PlayerService
    let youtubePlayerService: YouTubePlayerService

    var fullScreenCommandTitle: String {
        if self.settings.appSource == .video {
            let isFullScreen = self.youtubePlayerService.surfaceLocation == .floating
                ? self.youtubePlayerService.isWindowFullscreen
                : self.youtubePlayerService.showFullScreenVideo
            return isFullScreen
                ? String(localized: "Exit Full Screen")
                : String(localized: "Full Screen")
        }
        return self.playerService.showFullScreenPlayer
            ? String(localized: "Exit Full Screen Player")
            : String(localized: "Full Screen Player")
    }

    var shouldDisableFullScreenCommand: Bool {
        if self.settings.appSource == .video {
            let isFullScreen = self.youtubePlayerService.surfaceLocation == .floating
                ? self.youtubePlayerService.isWindowFullscreen
                : self.youtubePlayerService.showFullScreenVideo
            return self.youtubePlayerService.currentVideo == nil && !isFullScreen
        }
        return self.playerService.currentTrack == nil && !self.playerService.showFullScreenPlayer
    }

    func toggleFullScreenAction() {
        if self.settings.appSource == .video {
            if self.youtubePlayerService.surfaceLocation == .floating {
                YouTubeVideoWindowController.shared.toggleFullscreen()
            } else {
                self.toggleYouTubeInlineFullScreen()
            }
        } else {
            guard self.playerService.currentTrack != nil || self.playerService.showFullScreenPlayer else { return }
            HapticService.toggle()
            withAnimation(AppAnimation.standard) {
                self.playerService.showFullScreenPlayer.toggle()
            }
        }
    }

    func toggleYouTubeInlineFullScreen() {
        guard self.youtubePlayerService.currentVideo != nil || self.youtubePlayerService.showFullScreenVideo else { return }
        HapticService.toggle()
        withAnimation(AppAnimation.quick) {
            self.youtubePlayerService.toggleFullScreenVideo()
        }
    }

    var pictureInPictureCommandTitle: String {
        if self.settings.appSource == .video {
            return self.youtubePlayerService.surfaceLocation == .floating
                ? String(localized: "Pop video back into Kaset")
                : String(localized: "Picture in Picture")
        }
        if self.playerService.showVideo {
            return String(localized: "Pop video back into Kaset")
        }
        return self.playerService.isMiniPlayerVisible
            ? String(localized: "Return to Kaset")
            : String(localized: "Picture in Picture")
    }

    var shouldDisablePictureInPictureCommand: Bool {
        if self.settings.appSource == .video {
            return self.youtubePlayerService.currentVideo == nil || self.youtubePlayerService.isWindowFullscreen
        }
        return self.playerService.currentTrack == nil && !self.playerService.isMiniPlayerVisible
    }

    func togglePictureInPictureAction() {
        if self.settings.appSource == .video {
            guard !self.youtubePlayerService.isWindowFullscreen else { return }
            HapticService.toggle()
            if self.youtubePlayerService.showFullScreenVideo {
                self.youtubePlayerService.showFullScreenVideo = false
            }
            if self.youtubePlayerService.surfaceLocation == .floating {
                self.youtubePlayerService.requestPopIn()
            } else {
                self.youtubePlayerService.popOutToWindow()
            }
        } else {
            HapticService.toggle()
            if self.playerService.showVideo {
                withAnimation(AppAnimation.standard) {
                    self.playerService.showVideo = false
                }
            } else if self.playerService.showFullScreenPlayer {
                withAnimation(AppAnimation.standard) {
                    self.playerService.showFullScreenPlayer = false
                }
                _ = self.playerService.toggleMiniPlayer(mode: .switchFromMainWindow)
            } else if self.playerService.isMiniPlayerVisible {
                _ = self.playerService.closeMiniPlayer(restoringMainWindow: true)
            } else {
                self.playerService.openMiniPlayer(mode: .switchFromMainWindow)
            }
        }
    }
}
