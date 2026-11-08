import JavaScriptCore
import Testing
@testable import Kaset

@Suite("YouTube watch keyboard script")
@MainActor
struct YouTubeWatchKeyboardScriptTests {
    @Test("An extracted player forwards F with its document generation")
    func extractedPlayerFullScreenShortcut() throws {
        let context = try self.makeContext()
        context.evaluateScript("fireKey({ key: 'F' });")
        #expect(context.evaluateScript("messages.length").toInt32() == 1)
        #expect(context.evaluateScript("messages[0].type").toString() == "TOGGLE_FULLSCREEN")
        #expect(context.evaluateScript("messages[0].documentGeneration").toInt32() == 7)
        #expect(context.evaluateScript("prevented").toInt32() == 1)
        #expect(context.evaluateScript("stopped").toInt32() == 1)
    }

    @Test("Interstitials and editable content keep their F key", arguments: [
        "window.__kasetYTVideoActive = false;",
        "document.activeElement = { tagName: 'INPUT' };",
        "document.activeElement = { tagName: 'TEXTAREA' };",
        "document.activeElement = { tagName: 'SELECT' };",
        "document.activeElement = { isContentEditable: true };",
        "target = { tagName: 'INPUT' };",
        "target = { isContentEditable: true };",
        "shadowTarget = { tagName: 'INPUT' };",
    ])
    func editingAndInterstitials(setup: String) throws {
        let context = try self.makeContext()
        context.evaluateScript(setup)
        context.evaluateScript("fireKey({});")
        #expect(context.exception == nil)
        #expect(context.evaluateScript("messages.length").toInt32() == 0)
        #expect(context.evaluateScript("prevented").toInt32() == 0)
    }

    @Test("Modified keys and composition remain with WebKit", arguments: [
        "{ metaKey: true }", "{ ctrlKey: true }", "{ altKey: true }",
        "{ shiftKey: true }", "{ isComposing: true }", "{ defaultPrevented: true }", "{ key: 'm' }",
    ])
    func otherKeyboardInput(event: String) throws {
        let context = try self.makeContext()
        context.evaluateScript("fireKey(\(event));")
        #expect(context.exception == nil)
        #expect(context.evaluateScript("messages.length").toInt32() == 0)
        #expect(context.evaluateScript("prevented").toInt32() == 0)
    }

    @Test("Key repeat cannot toggle either native or YouTube fullscreen again")
    func keyRepeat() throws {
        let context = try self.makeContext()
        context.evaluateScript("fireKey({ repeat: true });")
        #expect(context.evaluateScript("messages.length").toInt32() == 0)
        #expect(context.evaluateScript("prevented").toInt32() == 1)
        #expect(context.evaluateScript("stopped").toInt32() == 1)
    }

    private func makeContext() throws -> JSContext {
        let context = try #require(JSContext())
        context.evaluateScript(
            """
            var messages = [], prevented = 0, stopped = 0;
            var target = {}, shadowTarget = null, keyListener;
            var window = {
                __kasetYTVideoActive: true,
                __kasetDocumentGeneration: 7,
                webkit: { messageHandlers: { youtubePlayer: {
                    postMessage: function(message) { messages.push(message); }
                } } }
            };
            var document = {
                activeElement: null,
                addEventListener: function(name, listener) { keyListener = listener; }
            };
            function fireKey(overrides) {
                const event = Object.assign({
                    key: 'f', target: target,
                    composedPath: function() { return shadowTarget ? [shadowTarget] : [target]; },
                    preventDefault: function() { prevented++; },
                    stopImmediatePropagation: function() { stopped++; }
                }, overrides);
                keyListener(event);
            }
            """
        )
        context.evaluateScript(YouTubeWatchWebView.fullScreenShortcutScript)
        #expect(context.exception == nil)
        return context
    }
}
