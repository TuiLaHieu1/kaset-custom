import AppKit
import SwiftUI
import WebKit

// MARK: - YouTubeFullScreenKeyAction

enum YouTubeFullScreenKeyAction: Equatable {
    case exit, playPause, pictureInPicture, mute
    case seekBackward, seekForward, skipBackward, skipForward
    case volumeUp, volumeDown, consumeRepeat

    static func action(for event: NSEvent) -> Self? {
        // Arrow keys also carry numericPad/function; Caps Lock is not a shortcut modifier.
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        let action: Self? = switch (event.keyCode, modifiers) {
        case (53, []): .exit
        case (49, []): .playPause
        case (123, []): .seekBackward
        case (124, []): .seekForward
        case (123, .command): .skipBackward
        case (124, .command): .skipForward
        case (126, []), (126, .command): .volumeUp
        case (125, []), (125, .command): .volumeDown
        default:
            Self.letterAction(event.charactersIgnoringModifiers?.lowercased(), modifiers: modifiers)
        }
        guard let action else { return nil }
        if event.isARepeat, [.exit, .playPause, .pictureInPicture, .mute].contains(action) {
            return .consumeRepeat
        }
        return action
    }

    private static func letterAction(_ characters: String?, modifiers: NSEvent.ModifierFlags) -> Self? {
        switch (characters, modifiers) {
        case ("f", []): .exit
        case ("m", []): .mute
        case ("p", .command): .pictureInPicture
        default: nil
        }
    }

    @MainActor
    static func accepts(_ event: NSEvent, in window: NSWindow?) -> Bool {
        guard let window, event.window === window, window.attachedSheet == nil else { return false }
        return !Self.defersToResponder(window.firstResponder)
    }

    @MainActor
    static func defersToResponder(_ responder: NSResponder?) -> Bool {
        if responder is NSTextView || responder is NSTextField {
            return true
        }
        // WebKit's HTML editor is a private descendant view, not an NSTextField.
        var view = responder as? NSView
        while let current = view {
            if current is WKWebView {
                return true
            }
            view = current.superview
        }
        return false
    }
}

// MARK: - YouTubeFullScreenKeyMonitor

/// A local monitor limited to the window hosting the full screen player.
@MainActor
struct YouTubeFullScreenKeyMonitor: NSViewRepresentable {
    let onKey: @MainActor (NSEvent) -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onKey: self.onKey)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.install(for: view)
        return view
    }

    func updateNSView(_: NSView, context: Context) {
        context.coordinator.onKey = self.onKey
    }

    static func dismantleNSView(_: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    @MainActor
    final class Coordinator {
        var onKey: @MainActor (NSEvent) -> Bool
        private var monitor: Any?

        init(onKey: @escaping @MainActor (NSEvent) -> Bool) {
            self.onKey = onKey
        }

        func install(for view: NSView) {
            guard self.monitor == nil else { return }
            self.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak view] event in
                guard let self,
                      let window = view?.window,
                      window.isKeyWindow,
                      YouTubeFullScreenKeyAction.accepts(event, in: window)
                else { return event }
                return self.onKey(event) ? nil : event
            }
        }

        func uninstall() {
            guard let monitor = self.monitor else { return }
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
