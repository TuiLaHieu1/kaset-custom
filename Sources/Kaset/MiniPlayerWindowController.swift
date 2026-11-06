import AppKit
import SwiftUI

// MARK: - MiniPlayerWindowLevelPolicy

/// Deterministic presentation policy for the YouTube Music mini player.
/// Desired state lives in `SettingsManager`; the controller decides when it is
/// safe to apply that state to the live AppKit window.
@MainActor
enum MiniPlayerWindowLevelPolicy {
    static let requiredCollectionBehavior: NSWindow.CollectionBehavior = [
        .canJoinAllSpaces,
        .fullScreenAuxiliary,
    ]

    static func windowLevel(isPinned: Bool) -> NSWindow.Level {
        isPinned ? .floating : .normal
    }

    static func collectionBehavior(
        preserving current: NSWindow.CollectionBehavior
    ) -> NSWindow.CollectionBehavior {
        var behavior = current
        behavior.remove(.transient)
        behavior.remove(.stationary)
        behavior.remove(.ignoresCycle)
        behavior.formUnion(self.requiredCollectionBehavior)
        return behavior
    }

    static func configureCollectionBehavior(of window: NSWindow) {
        window.collectionBehavior = self.collectionBehavior(preserving: window.collectionBehavior)
    }

    static func applyWindowLevel(isPinned: Bool, to window: NSWindow) {
        window.level = self.windowLevel(isPinned: isPinned)
        self.configureCollectionBehavior(of: window)
    }
}

// MARK: - MiniPlayerWindowController

/// Manages the Apple Music-style floating mini player window.
@MainActor
final class MiniPlayerWindowController {
    static let shared = MiniPlayerWindowController()

    private var window: NSWindow?
    private var hostingView: NSHostingView<AnyView>?
    private weak var playerService: PlayerService?
    private var isClosing = false

    private let frameAutosaveKey = "KasetMiniPlayerWindow"

    private init() {}

    /// Creates an isolated controller without presenting a window or loading playback.
    static func makeTestInstance(window: NSWindow, playerService: PlayerService) -> MiniPlayerWindowController {
        let controller = MiniPlayerWindowController()
        controller.window = window
        controller.playerService = playerService
        controller.observeWindow(window)
        return controller
    }

    func show(
        playerService: PlayerService,
        client: any YTMusicClientProtocol,
        syncedLyricsService: SyncedLyricsService,
        authService: AuthService
    ) {
        self.playerService = playerService

        let contentView = MiniPlayerWindow(client: client)
            .environment(playerService)
            .environment(WebKitManager.shared)
            .environment(authService)
            .environment(FavoritesManager.shared)
            .environment(SongLikeStatusManager.shared)
            .environment(syncedLyricsService)

        if let existingWindow = self.window {
            self.isClosing = false
            if let miniWindow = existingWindow as? MiniPlayerNSWindow {
                miniWindow.playerService = playerService
            }
            playerService.isMiniPlayerMiniaturized = existingWindow.isMiniaturized
            self.hostingView?.rootView = AnyView(contentView)
            existingWindow.delegate = nil
            Self.hideStandardWindowButtons(existingWindow)
            self.applyWindowLevel(existingWindow)
            self.applySize(for: playerService.miniPlayerPanel, window: existingWindow, animated: false)
            existingWindow.orderFront(nil)
            return
        }

        let hostingView = NSHostingView(rootView: AnyView(contentView))
        self.hostingView = hostingView

        let window = MiniPlayerNSWindow(
            contentRect: Self.contentRect(for: playerService.miniPlayerPanel),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.playerService = playerService
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.title = "Mini Player"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.delegate = nil
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.identifier = NSUserInterfaceItemIdentifier(AccessibilityID.MiniPlayer.container)
        window.setFrameAutosaveName(self.frameAutosaveKey)
        Self.hideStandardWindowButtons(window)
        self.applyWindowLevel(window)

        let restored = window.setFrameUsingName(self.frameAutosaveKey)
        if !restored {
            self.positionAtDefaultLocation(window: window)
        }
        self.applySize(for: playerService.miniPlayerPanel, window: window, animated: false, isInitialRestore: restored)

        self.observeWindow(window)
        window.orderFront(nil)
        self.window = window
        self.isClosing = false
    }

    func close() {
        guard !self.isClosing else { return }
        guard let window = self.window else { return }

        self.isClosing = true
        NotificationCenter.default.removeObserver(self, name: nil, object: window)
        window.saveFrame(usingName: self.frameAutosaveKey)
        self.performCleanup()
        window.close()
    }

    func closeFromUserAction() {
        _ = self.playerService?.closeMiniPlayer() ?? false
        self.close()
    }

    func returnToMainWindowFromUserAction() {
        _ = self.playerService?.closeMiniPlayer(restoringMainWindow: true) ?? false
        self.close()
    }

    func miniaturizeFromUserAction() {
        self.window?.miniaturize(nil)
    }

    func syncWindowState() {
        guard let window, let playerService else { return }
        self.applyWindowLevel(window)
        self.applySize(for: playerService.miniPlayerPanel, window: window, animated: true)
    }

    func orderFrontIfVisible() {
        self.window?.orderFrontRegardless()
    }

    private func observeWindow(_ window: NSWindow) {
        self.playerService?.isMiniPlayerMiniaturized = window.isMiniaturized
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.windowWillClose),
            name: NSWindow.willCloseNotification,
            object: window
        )
        for name in [NSWindow.didMiniaturizeNotification, NSWindow.didDeminiaturizeNotification] {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.windowMiniaturizationChanged),
                name: name,
                object: window
            )
        }
    }

    @objc private func windowMiniaturizationChanged(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === self.window else { return }
        self.playerService?.isMiniPlayerMiniaturized = notification.name == NSWindow.didMiniaturizeNotification
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard !self.isClosing else { return }
        self.isClosing = true

        if let window = notification.object as? NSWindow {
            window.saveFrame(usingName: self.frameAutosaveKey)
        }

        _ = self.playerService?.closeMiniPlayer() ?? false
        self.performCleanup()
    }

    private func performCleanup() {
        if let miniWindow = self.window as? MiniPlayerNSWindow {
            miniWindow.playerService = nil
        }
        if let window {
            NotificationCenter.default.removeObserver(self, name: nil, object: window)
        }
        self.playerService?.isMiniPlayerMiniaturized = false
        self.window = nil
        self.hostingView = nil
        self.playerService = nil
        self.isClosing = false
    }

    private func applyWindowLevel(_ window: NSWindow) {
        MiniPlayerWindowLevelPolicy.applyWindowLevel(
            isPinned: SettingsManager.shared.keepMiniPlayerOnTop,
            to: window
        )
    }

    private func applySize(
        for panel: PlayerService.MiniPlayerPanel,
        window: NSWindow,
        animated: Bool = false,
        isInitialRestore: Bool = false
    ) {
        let minSize = Self.minContentSize(for: panel)
        let maxSize = Self.maxContentSize(for: panel)
        window.minSize = minSize
        window.maxSize = maxSize
        window.contentMinSize = minSize
        window.contentMaxSize = maxSize

        let currentFrame = window.frame
        var targetSize = currentFrame.size

        if isInitialRestore {
            targetSize.width = min(max(currentFrame.width, minSize.width), maxSize.width)
            targetSize.height = min(max(currentFrame.height, minSize.height), maxSize.height)
        } else if animated {
            let defaultSize = Self.defaultContentSize(for: panel)
            let preservedWidth = min(max(currentFrame.width, minSize.width), maxSize.width)

            switch panel {
            case .compact:
                targetSize.width = preservedWidth
                targetSize.height = defaultSize.height
            case .expanded:
                let dim = max(preservedWidth, defaultSize.height)
                targetSize.width = dim
                targetSize.height = dim
            case .lyrics:
                targetSize.width = max(preservedWidth, defaultSize.width)
                targetSize.height = max(currentFrame.height, defaultSize.height)
            }
        } else {
            targetSize = Self.defaultContentSize(for: panel)
        }

        var nextFrame = currentFrame
        nextFrame.origin.y += currentFrame.height - targetSize.height
        nextFrame.size = targetSize
        window.setFrame(nextFrame, display: true, animate: animated)
    }

    private func positionAtDefaultLocation(window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let padding: CGFloat = 32
        window.setFrameOrigin(
            NSPoint(
                x: screenFrame.maxX - windowSize.width - padding,
                y: screenFrame.maxY - windowSize.height - padding
            )
        )
    }

    static func minContentSize(for panel: PlayerService.MiniPlayerPanel) -> NSSize {
        switch panel {
        case .compact:
            NSSize(width: 260, height: 140)
        case .expanded:
            NSSize(width: 240, height: 240)
        case .lyrics:
            NSSize(width: 280, height: 350)
        }
    }

    static func maxContentSize(for panel: PlayerService.MiniPlayerPanel) -> NSSize {
        switch panel {
        case .compact:
            NSSize(width: 500, height: 260)
        case .expanded:
            NSSize(width: 650, height: 650)
        case .lyrics:
            NSSize(width: 650, height: 900)
        }
    }

    static func defaultContentSize(for panel: PlayerService.MiniPlayerPanel) -> NSSize {
        switch panel {
        case .compact:
            NSSize(width: 320, height: 184)
        case .expanded:
            NSSize(width: 320, height: 320)
        case .lyrics:
            NSSize(width: 320, height: 500)
        }
    }

    private static func contentRect(for panel: PlayerService.MiniPlayerPanel) -> NSRect {
        NSRect(origin: .zero, size: self.defaultContentSize(for: panel))
    }

    private static func hideStandardWindowButtons(_ window: NSWindow) {
        [
            NSWindow.ButtonType.closeButton,
            .miniaturizeButton,
            .zoomButton,
        ].forEach { buttonType in
            window.standardWindowButton(buttonType)?.isHidden = true
        }
    }
}

// MARK: - MiniPlayerNSWindow

/// Custom NSWindow for the mini player that prevents embedded scroll views (e.g. lyrics and queue)
/// from swallowing playback keyboard shortcuts like ⌘↑ (Volume Up) and ⌘↓ (Volume Down).
@MainActor
final class MiniPlayerNSWindow: NSWindow {
    weak var playerService: PlayerService?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers == .command, !(self.firstResponder is NSText) {
            let isDown = event.keyCode == 125 || event.specialKey == .downArrow
            let isUp = event.keyCode == 126 || event.specialKey == .upArrow
            if isDown || isUp {
                if let playerService = self.playerService {
                    let delta = isUp ? 0.1 : -0.1
                    Task { @MainActor in
                        await playerService.setVolume(min(1.0, max(0.0, playerService.volume + delta)))
                    }
                    return true
                }
            }

            let isLeft = event.keyCode == 123 || event.specialKey == .leftArrow
            let isRight = event.keyCode == 124 || event.specialKey == .rightArrow
            if isLeft {
                if let playerService = self.playerService {
                    Task { @MainActor in
                        await playerService.previous()
                    }
                    return true
                }
            } else if isRight {
                if let playerService = self.playerService {
                    Task { @MainActor in
                        await playerService.next()
                    }
                    return true
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
