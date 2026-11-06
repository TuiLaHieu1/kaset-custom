import SwiftUI

/// Loading overlay displayed on top of the YouTube video surface while
/// the WebKit player is navigating and initializing media.
///
/// Shows the high-resolution video thumbnail with a subtle dark backdrop
/// and a centered progress spinner with a "Loading video…" status label,
/// avoiding a disorienting pitch-black box during page loads.
struct YouTubeWatchLoadingOverlay: View {
    let thumbnailURL: URL?

    var body: some View {
        ZStack {
            CachedAsyncImage(
                url: self.thumbnailURL,
                targetSize: CGSize(width: 1280, height: 720)
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle().fill(.black)
            }

            Color.black.opacity(0.35)

            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.2)

                Text("Loading video…", comment: "Loading indicator label while video is loading")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Loading video", comment: "Accessibility label for video loading state"))
    }
}
