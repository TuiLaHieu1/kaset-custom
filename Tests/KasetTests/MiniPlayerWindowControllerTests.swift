import AppKit
import Testing
@testable import Kaset

// MARK: - MiniPlayerWindowControllerTests

@Suite("Mini player playback hosting", .serialized, .tags(.service))
@MainActor
struct MiniPlayerWindowControllerTests {
    @Test("Minimizing and restoring an open mini player transfers playback hosting", arguments: [
        PlayerService.MiniPlayerMode.auxiliary,
        .switchFromMainWindow,
    ])
    func miniaturizationTransfersPlaybackHosting(mode: PlayerService.MiniPlayerMode) {
        let playerService = PlayerService()
        playerService.openMiniPlayer(mode: mode)
        let window = Self.makeWindow()
        let controller = MiniPlayerWindowController.makeTestInstance(window: window, playerService: playerService)
        defer { controller.close() }
        #expect(playerService.shouldHostPlaybackInMiniPlayer)

        NotificationCenter.default.post(name: NSWindow.didMiniaturizeNotification, object: window)

        #expect(playerService.isMiniPlayerVisible)
        #expect(playerService.isMiniPlayerMiniaturized)
        #expect(!playerService.shouldHostPlaybackInMiniPlayer)

        let otherWindow = Self.makeWindow()
        defer { otherWindow.close() }
        NotificationCenter.default.post(name: NSWindow.didDeminiaturizeNotification, object: otherWindow)
        #expect(!playerService.shouldHostPlaybackInMiniPlayer)

        NotificationCenter.default.post(name: NSWindow.didDeminiaturizeNotification, object: window)

        #expect(playerService.isMiniPlayerVisible)
        #expect(!playerService.isMiniPlayerMiniaturized)
        #expect(playerService.shouldHostPlaybackInMiniPlayer)

        playerService.showVideo = true
        NotificationCenter.default.post(name: NSWindow.didMiniaturizeNotification, object: window)
        NotificationCenter.default.post(name: NSWindow.didDeminiaturizeNotification, object: window)
        #expect(!playerService.shouldHostPlaybackInMiniPlayer)
    }

    @Test("Closing a minimized window clears its state and ignores late notifications")
    func closingMinimizedWindowClearsState() {
        let playerService = PlayerService()
        playerService.openMiniPlayer()
        let window = Self.makeWindow()
        let controller = MiniPlayerWindowController.makeTestInstance(window: window, playerService: playerService)
        defer { controller.close() }
        NotificationCenter.default.post(name: NSWindow.didMiniaturizeNotification, object: window)
        #expect(playerService.isMiniPlayerMiniaturized)

        controller.closeFromUserAction()

        #expect(!playerService.isMiniPlayerVisible)
        #expect(!playerService.isMiniPlayerMiniaturized)
        #expect(!playerService.shouldHostPlaybackInMiniPlayer)

        playerService.openMiniPlayer()
        NotificationCenter.default.post(name: NSWindow.didMiniaturizeNotification, object: window)
        #expect(!playerService.isMiniPlayerMiniaturized)
        #expect(playerService.shouldHostPlaybackInMiniPlayer)
    }

    @Test("Syncing window state applies the current pin setting to the live window")
    func syncWindowStateAppliesWindowLevel() {
        let playerService = PlayerService()
        playerService.openMiniPlayer()
        let window = Self.makeWindow()
        let controller = MiniPlayerWindowController.makeTestInstance(window: window, playerService: playerService)
        defer {
            SettingsManager.shared.keepMiniPlayerOnTop = false
            controller.close()
        }

        SettingsManager.shared.keepMiniPlayerOnTop = false
        controller.syncWindowState()
        #expect(window.level == .normal)

        SettingsManager.shared.keepMiniPlayerOnTop = true
        controller.syncWindowState()
        #expect(window.level == .floating)

        SettingsManager.shared.keepMiniPlayerOnTop = false
        controller.syncWindowState()
        #expect(window.level == .normal)
    }

    @Test("Panel sizing bounds enforce flexible resizability limits")
    func panelSizingBounds() {
        let compactMin = MiniPlayerWindowController.minContentSize(for: .compact)
        let compactMax = MiniPlayerWindowController.maxContentSize(for: .compact)
        let compactDefault = MiniPlayerWindowController.defaultContentSize(for: .compact)

        #expect(compactMin.width == 260)
        #expect(compactMin.height == 140)
        #expect(compactMax.width == 500)
        #expect(compactMax.height == 260)
        #expect(compactDefault.width == 320)
        #expect(compactDefault.height == 184)

        let expandedMin = MiniPlayerWindowController.minContentSize(for: .expanded)
        let expandedMax = MiniPlayerWindowController.maxContentSize(for: .expanded)
        #expect(expandedMin.width == 240)
        #expect(expandedMin.height == 240)
        #expect(expandedMax.width >= 600)
        #expect(expandedMax.height >= 600)

        let lyricsMin = MiniPlayerWindowController.minContentSize(for: .lyrics)
        let lyricsMax = MiniPlayerWindowController.maxContentSize(for: .lyrics)
        #expect(lyricsMin.width == 280)
        #expect(lyricsMin.height == 350)
        #expect(lyricsMax.width >= 600)
        #expect(lyricsMax.height >= 850)
    }

    @Test("MiniPlayerNSWindow intercepts ⌘↑ and ⌘↓ for volume control")
    func miniPlayerWindowInterceptsVolumeShortcuts() async {
        let playerService = PlayerService()
        playerService.volume = 0.5
        let window = MiniPlayerNSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 184),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.playerService = playerService

        // Command + Down Arrow (keyCode 125) -> Volume Down
        if let downEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: .command,
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: 125
        ) {
            let handled = window.performKeyEquivalent(with: downEvent)
            #expect(handled)
            try? await Task.sleep(for: .milliseconds(50))
            #expect(playerService.volume < 0.5)
        }

        // Command + Up Arrow (keyCode 126) -> Volume Up
        if let upEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: .command,
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: 126
        ) {
            let handled = window.performKeyEquivalent(with: upEvent)
            #expect(handled)
            try? await Task.sleep(for: .milliseconds(50))
            #expect(playerService.volume >= 0.5)
        }
    }

    private static func makeWindow() -> NSWindow {
        let window = MiniPlayerTestWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 184),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        return window
    }
}

// MARK: - MiniPlayerTestWindow

@MainActor
private final class MiniPlayerTestWindow: NSWindow {
    override func saveFrame(usingName _: NSWindow.FrameAutosaveName) {}
}
