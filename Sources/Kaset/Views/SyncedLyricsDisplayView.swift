import SwiftUI

// MARK: - SyncedLyricsDisplayView

struct SyncedLyricsDisplayView: View {
    enum PresentationStyle {
        case sidebar
        case fullScreen
    }

    let lyrics: SyncedLyrics
    let currentLineIndex: Int?
    let displayTimeMs: Int?
    var style: PresentationStyle = .sidebar
    let onSeek: (Int) -> Void

    @State private var currentLineId: UUID?

    private var effectiveDisplayTimeMs: Int {
        self.displayTimeMs ?? -1
    }

    private var isFullScreen: Bool {
        self.style == .fullScreen
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: self.isFullScreen ? .leading : .center, spacing: self.isFullScreen ? 28 : 20) {
                    Spacer().frame(height: self.isFullScreen ? 220 : 150) // Top padding

                    ForEach(self.lyrics.lines.indices, id: \.self) { lineIndex in
                        let line = self.lyrics.lines[lineIndex]
                        let status = self.currentStatus(for: line, at: lineIndex)
                        SyncedLineView(
                            line: line,
                            status: status,
                            style: self.style,
                            onTap: { self.onSeek(line.timeInMs) }
                        )
                        .id(line.id)
                    }

                    Spacer().frame(height: self.isFullScreen ? 260 : 150) // Bottom padding
                }
                .padding(.horizontal, self.isFullScreen ? 32 : 24)
            }
            .scrollIndicators(.hidden)
            .onChange(of: self.currentLineIndex, initial: true) { _, newLineIndex in
                guard let newLineIndex,
                      self.lyrics.lines.indices.contains(newLineIndex)
                else { return }

                let newId = self.lyrics.lines[newLineIndex].id
                guard newId != self.currentLineId else { return }

                self.currentLineId = newId
                withAnimation(.spring(response: 0.75, dampingFraction: 0.85)) {
                    // Target center for natural scrolling
                    proxy.scrollTo(newId, anchor: .center)
                }
            }
        }
    }

    private func currentStatus(for line: SyncedLyricLine, at lineIndex: Int) -> SyncedLyrics.LineStatus {
        if let currentLineIndex, self.lyrics.lines.indices.contains(currentLineIndex) {
            if lineIndex < currentLineIndex {
                return .previous
            }
            if lineIndex > currentLineIndex {
                return .upcoming
            }
            return .current
        }

        return line.timeInMs <= self.effectiveDisplayTimeMs ? .previous : .upcoming
    }
}

// MARK: - SyncedLineView

struct SyncedLineView: View {
    let line: SyncedLyricLine
    let status: SyncedLyrics.LineStatus
    var style: SyncedLyricsDisplayView.PresentationStyle = .sidebar
    let onTap: () -> Void

    @State private var isHovered = false

    private var isFullScreen: Bool {
        self.style == .fullScreen
    }

    /// Smooth Apple TV spring transition
    private let animation = Animation.spring(response: 0.45, dampingFraction: 0.82)

    var body: some View {
        VStack(alignment: self.isFullScreen ? .leading : .center, spacing: self.isFullScreen ? 8 : 4) {
            // Original text
            Text(self.line.text.isEmpty ? "♪" : self.line.text)
                .font(self.primaryFont)
                .foregroundStyle(self.primaryTextColor)
                .lineSpacing(self.isFullScreen ? 8 : 4)

            // Romanized text (only if present and differs from original)
            if let romaji = self.line.romanizedText {
                Text(romaji)
                    .font(self.romanizedFont)
                    .italic()
                    .foregroundStyle(self.romanizedTextColor)
            }
        }
        .opacity(self.overallOpacity)
        .blur(radius: self.blurRadius)
        .scaleEffect(self.scale)
        .animation(self.animation, value: self.status)
        .animation(self.animation, value: self.isHovered)
        .multilineTextAlignment(self.isFullScreen ? .leading : .center)
        .lineLimit(nil)
        // Use content shape to allow tapping on empty space around text too
        .contentShape(Rectangle())
        .onTapGesture {
            self.onTap()
        }
        .onHover { hovering in
            self.isHovered = hovering
        }
        .pointerStyle(.link)
        .padding(.vertical, self.isFullScreen ? 6 : 4)
    }

    private var primaryFont: Font {
        if self.isFullScreen {
            return self.status == .current
                ? .system(size: 40, weight: .bold, design: .default)
                : .system(size: 32, weight: .bold, design: .default)
        } else {
            return self.status == .current
                ? .system(size: 26, weight: .bold, design: .default)
                : .system(size: 20, weight: .medium, design: .default)
        }
    }

    private var romanizedFont: Font {
        if self.isFullScreen {
            return self.status == .current
                ? .system(size: 22, weight: .medium, design: .default)
                : .system(size: 18, weight: .regular, design: .default)
        } else {
            return self.status == .current
                ? .system(size: 18, weight: .regular, design: .default)
                : .system(size: 14, weight: .regular, design: .default)
        }
    }

    private var primaryTextColor: Color {
        if self.isFullScreen {
            return .white
        } else {
            return self.status == .current ? .primary : (self.status == .previous ? .secondary : .secondary.opacity(0.6))
        }
    }

    private var romanizedTextColor: Color {
        if self.isFullScreen {
            return .white.opacity(self.status == .current ? 0.85 : 0.6)
        } else {
            return self.status == .current ? .secondary : .secondary.opacity(0.6)
        }
    }

    private var overallOpacity: Double {
        if self.isFullScreen {
            if self.status == .current {
                return 1.0
            } else if self.isHovered {
                return 0.75
            } else {
                return 0.38
            }
        } else {
            if self.status == .current {
                return 1.0
            } else if self.isHovered {
                return 0.8
            } else {
                return self.status == .previous ? 0.6 : 0.4
            }
        }
    }

    private var blurRadius: CGFloat {
        if self.isFullScreen {
            return (self.status == .current || self.isHovered) ? 0 : 1.2
        } else {
            return (self.status == .current || self.isHovered) ? 0 : 0.5
        }
    }

    private var scale: CGFloat {
        if self.isFullScreen {
            return self.status == .current ? 1.0 : 0.98
        } else {
            return self.status == .current ? 1.05 : 1.0
        }
    }
}
