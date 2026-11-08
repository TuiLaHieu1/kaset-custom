import AppKit
import Testing
@testable import Kaset

// MARK: - YouTubeWatchSurfaceOwnershipTests

@MainActor
struct YouTubeWatchSurfaceOwnershipTests {
    @Test("A dismissed fullscreen host cannot claim a floating surface", arguments: [false, true])
    func fullscreenHostCannotClaimFloatingSurface(showFullScreenVideo: Bool) {
        #expect(!YouTubeWatchSurfaceAttachment.acceptsPresentation(
            isFullScreen: true,
            location: .floating,
            showFullScreenVideo: showFullScreenVideo
        ))
    }

    @Test("Fullscreen and inline hosts only claim their active inline presentation")
    func inlinePresentationOwnership() {
        #expect(YouTubeWatchSurfaceAttachment.acceptsPresentation(
            isFullScreen: true, location: .inline, showFullScreenVideo: true
        ))
        #expect(!YouTubeWatchSurfaceAttachment.acceptsPresentation(
            isFullScreen: true, location: .inline, showFullScreenVideo: false
        ))
        #expect(YouTubeWatchSurfaceAttachment.acceptsPresentation(
            isFullScreen: false, location: .inline, showFullScreenVideo: false
        ))
        #expect(!YouTubeWatchSurfaceAttachment.acceptsPresentation(
            isFullScreen: false, location: .inline, showFullScreenVideo: true
        ))
    }

    @Test("A late outgoing Shorts host cannot reclaim the selected surface")
    func lateOutgoingShortsHostCannotReclaimSelectedSurface() {
        let surface = NSView()
        let firstContainer = NSView()
        let secondContainer = NSView()

        #expect(YouTubeWatchSurfaceAttachment.claim(
            surface: surface,
            in: firstContainer,
            expectedVideoId: "short-a",
            currentVideoId: "short-a"
        ))
        #expect(YouTubeWatchSurfaceAttachment.claim(
            surface: surface,
            in: secondContainer,
            expectedVideoId: "short-b",
            currentVideoId: "short-b"
        ))
        #expect(!YouTubeWatchSurfaceAttachment.claim(
            surface: surface,
            in: firstContainer,
            expectedVideoId: "short-a",
            currentVideoId: "short-b"
        ))
        #expect(!YouTubeWatchSurfaceAttachment.claim(
            surface: surface,
            in: firstContainer,
            expectedVideoId: "short-a",
            currentVideoId: nil
        ))

        #expect(surface.superview === secondContainer)
        #expect(!firstContainer.subviews.contains { $0 === surface })
    }

    @Test("Unscoped watch and floating hosts retain existing handoff behavior")
    func unscopedHostsCanClaimSurface() {
        let surface = NSView()
        let watchContainer = NSView()
        let floatingContainer = NSView()

        #expect(YouTubeWatchSurfaceAttachment.claim(
            surface: surface,
            in: watchContainer,
            expectedVideoId: nil,
            currentVideoId: nil
        ))
        #expect(YouTubeWatchSurfaceAttachment.claim(
            surface: surface,
            in: floatingContainer,
            expectedVideoId: nil,
            currentVideoId: "current-video"
        ))
        #expect(surface.superview === floatingContainer)
    }
}
