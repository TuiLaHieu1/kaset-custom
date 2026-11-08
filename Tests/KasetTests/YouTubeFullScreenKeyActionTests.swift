import AppKit
import Testing
import WebKit
@testable import Kaset

@Suite("YouTube full screen keyboard routing", .serialized)
@MainActor
struct YouTubeFullScreenKeyActionTests {
    @Test("Arrow metadata does not prevent seeking or volume control", arguments: [
        (UInt16(123), YouTubeFullScreenKeyAction.seekBackward),
        (UInt16(124), .seekForward),
        (UInt16(126), .volumeUp),
        (UInt16(125), .volumeDown),
    ])
    func arrowMetadata(keyCode: UInt16, action: YouTubeFullScreenKeyAction) throws {
        let event = try self.event(keyCode: keyCode, modifiers: [.numericPad, .function])
        #expect(YouTubeFullScreenKeyAction.action(for: event) == action)
    }

    @Test("Modified arrows preserve editing and macOS shortcuts", arguments: [
        NSEvent.ModifierFlags.option, .control, .shift, [.command, .shift],
    ])
    func unsupportedModifiers(modifiers: NSEvent.ModifierFlags) throws {
        for keyCode: UInt16 in [123, 124, 125, 126] {
            let event = try self.event(keyCode: keyCode, modifiers: modifiers)
            #expect(YouTubeFullScreenKeyAction.action(for: event) == nil)
        }
    }

    @Test("Caps Lock does not disable full screen shortcuts")
    func capsLock() throws {
        let event = try self.event(keyCode: 3, characters: "F", modifiers: .capsLock)
        #expect(YouTubeFullScreenKeyAction.action(for: event) == .exit)
    }

    @Test("Command navigation and PiP retain their existing meanings")
    func commandShortcuts() throws {
        let previous = try self.event(keyCode: 123, modifiers: [.command, .function, .numericPad])
        let next = try self.event(keyCode: 124, modifiers: .command)
        let pictureInPicture = try self.event(keyCode: 35, characters: "p", modifiers: .command)
        let minimize = try self.event(keyCode: 46, characters: "m", modifiers: .command)
        #expect(YouTubeFullScreenKeyAction.action(for: previous) == .skipBackward)
        #expect(YouTubeFullScreenKeyAction.action(for: next) == .skipForward)
        #expect(YouTubeFullScreenKeyAction.action(for: pictureInPicture) == .pictureInPicture)
        #expect(YouTubeFullScreenKeyAction.action(for: minimize) == nil)
    }

    @Test("Holding a toggle does not repeatedly pause, mute, or change presentation", arguments: [
        (UInt16(49), " ", NSEvent.ModifierFlags()),
        (UInt16(53), "\u{1B}", NSEvent.ModifierFlags()),
        (UInt16(3), "f", NSEvent.ModifierFlags()),
        (UInt16(46), "m", NSEvent.ModifierFlags()),
        (UInt16(35), "p", NSEvent.ModifierFlags.command),
    ])
    func repeatedToggle(keyCode: UInt16, characters: String, modifiers: NSEvent.ModifierFlags) throws {
        let event = try self.event(keyCode: keyCode, characters: characters, modifiers: modifiers, isRepeat: true)
        #expect(YouTubeFullScreenKeyAction.action(for: event) == .consumeRepeat)
    }

    @Test("Holding arrows continues to seek")
    func repeatedSeek() throws {
        let event = try self.event(keyCode: 124, isRepeat: true)
        #expect(YouTubeFullScreenKeyAction.action(for: event) == .seekForward)
    }

    @Test("The monitor leaves other windows and text editing alone")
    func windowAndEditingScope() throws {
        _ = NSApplication.shared
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: .titled,
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let event = try self.event(keyCode: 49, characters: " ", windowNumber: window.windowNumber)
        #expect(YouTubeFullScreenKeyAction.accepts(event, in: window))
        #expect(!YouTubeFullScreenKeyAction.accepts(event, in: nil))
        let otherWindowEvent = try self.event(keyCode: 49, windowNumber: 0)
        #expect(!YouTubeFullScreenKeyAction.accepts(otherWindowEvent, in: window))

        let textView = NSTextView(frame: .zero)
        window.contentView?.addSubview(textView)
        #expect(window.makeFirstResponder(textView))
        #expect(!YouTubeFullScreenKeyAction.accepts(event, in: window))
    }

    @Test("Native shortcuts defer to WebKit and its HTML editor descendants")
    func webContentFocus() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        let webContent = NSView()
        webView.addSubview(webContent)

        #expect(YouTubeFullScreenKeyAction.defersToResponder(webView))
        #expect(YouTubeFullScreenKeyAction.defersToResponder(webContent))
        #expect(!YouTubeFullScreenKeyAction.defersToResponder(NSView()))
    }

    private func event(
        keyCode: UInt16,
        characters: String = "",
        modifiers: NSEvent.ModifierFlags = [],
        isRepeat: Bool = false,
        windowNumber: Int = 0
    ) throws -> NSEvent {
        try #require(NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: windowNumber,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: isRepeat,
            keyCode: keyCode
        ))
    }
}
