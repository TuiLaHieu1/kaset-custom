import Testing
@testable import Kaset

@MainActor
struct YouTubePlayerVolumeTests {
    @Test("Unmute preserves volume after dismissing and recreating fullscreen")
    func unmuteAcrossFullScreenSessions() {
        let player = YouTubePlayerService(playbackController: MockYouTubeWatchPlaybackController())
        player.volume = 0.2
        player.showFullScreenVideo = true
        player.toggleMute()
        #expect(player.volume == 0)

        player.exitFullScreenVideo()
        player.showFullScreenVideo = true
        player.toggleMute()

        #expect(player.volume == 0.2)
    }

    @Test("Unmute restores the latest positive native volume")
    func unmuteAfterSliderReachesZero() {
        let player = YouTubePlayerService(playbackController: MockYouTubeWatchPlaybackController())
        player.volume = 0.35
        player.volume = 0

        player.toggleMute()

        #expect(player.volume == 0.35)
        player.volume = 0.1
        player.toggleMute()
        player.toggleMute()
        #expect(player.volume == 0.1)
    }
}
