import AppKit
import SwiftUI

// MARK: - YouTubeFullScreenPlayerView

/// A seamless full-screen video player covering the main window, with auto-hiding
/// playback controls on hover and responsive keyboard shortcut navigation.
struct YouTubeFullScreenPlayerView: View {
    @Environment(YouTubePlayerService.self) private var youtubePlayer

    @State private var isHovering = false
    @State private var isVolumeOverlayPresented = false
    @State private var hideControlsTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // 16:9 Aspect ratio video surface centered in the full window
            if let currentVideo = self.youtubePlayer.currentVideo {
                YouTubeWatchSurfaceView(isFullScreen: true)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        if self.youtubePlayer.isPlaybackLoading {
                            YouTubeWatchLoadingOverlay(thumbnailURL: currentVideo.thumbnailURL)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: self.youtubePlayer.isPlaybackLoading)
            }

            // Top exit button and bottom player controls
            if self.showsControls {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: self.exitFullScreen) {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help(String(localized: "Exit Full Screen (Esc / F)"))
                        .accessibilityLabel(String(localized: "Exit Full Screen"))
                        .padding(.leading, 24)
                        .padding(.top, 20)

                        Spacer()
                    }

                    Spacer()

                    // Bottom player bar with all playback controls
                    YouTubePlayerBar(
                        isDetachedWindow: false,
                        onVolumeOverlayChange: { isPresented in
                            self.isVolumeOverlayPresented = isPresented
                            if isPresented {
                                self.cancelHideTimer()
                            } else {
                                self.resetHideTimer()
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .transition(.opacity)
            }

            // Global key event monitor guaranteeing responsive shortcuts
            YouTubeFullScreenKeyMonitor(onKey: self.handleKeyEvent)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onHover { hovering in
            self.handleHover(hovering)
        }
        .onContinuousHover { phase in
            switch phase {
            case .active:
                self.revealControlsTemporarily()
            case .ended:
                break
            }
        }
        .onDisappear {
            self.cancelHideTimer()
        }
        .onExitCommand {
            self.exitFullScreen()
        }
    }

    private var showsControls: Bool {
        self.isHovering || self.isVolumeOverlayPresented
    }

    private func handleHover(_ hovering: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.isHovering = hovering
        }
        if hovering {
            self.resetHideTimer()
        } else {
            self.cancelHideTimer()
        }
    }

    private func revealControlsTemporarily() {
        if !self.isHovering {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isHovering = true
            }
        }
        self.resetHideTimer()
    }

    private func resetHideTimer() {
        self.cancelHideTimer()
        guard !self.isVolumeOverlayPresented else { return }
        self.hideControlsTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            if !self.isVolumeOverlayPresented {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isHovering = false
                }
            }
        }
    }

    private func cancelHideTimer() {
        self.hideControlsTask?.cancel()
        self.hideControlsTask = nil
    }

    private func exitFullScreen() {
        HapticService.toggle()
        withAnimation(AppAnimation.quick) {
            self.youtubePlayer.exitFullScreenVideo()
        }
    }

    private func togglePictureInPicture() {
        HapticService.toggle()
        self.youtubePlayer.exitFullScreenVideo()
        self.youtubePlayer.popOutToWindow()
    }

    @MainActor
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let action = YouTubeFullScreenKeyAction.action(for: event) else { return false }
        switch action {
        case .exit:
            self.exitFullScreen()
        case .playPause:
            self.youtubePlayer.playPause()
        case .pictureInPicture:
            self.togglePictureInPicture()
        case .mute:
            self.youtubePlayer.toggleMute()
        case .seekBackward:
            self.youtubePlayer.seekBackward(by: 10)
        case .seekForward:
            self.youtubePlayer.seekForward(by: 10)
        case .skipBackward:
            self.youtubePlayer.skipBackward()
        case .skipForward:
            Task { await self.youtubePlayer.skipForward() }
        case .volumeUp:
            self.youtubePlayer.volume = min(1, self.youtubePlayer.volume + 0.05)
        case .volumeDown:
            self.youtubePlayer.volume = max(0, self.youtubePlayer.volume - 0.05)
        case .consumeRepeat:
            return true
        }
        self.revealControlsTemporarily()
        return true
    }
}
