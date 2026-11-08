import Foundation

extension YouTubeWatchWebView {
    /// DOM focus is authoritative for HTML inputs and contenteditable elements.
    static var fullScreenShortcutScript: String {
        """
        document.addEventListener('keydown', function(event) {
            if (!window.__kasetYTVideoActive || event.defaultPrevented || event.isComposing ||
                event.metaKey || event.ctrlKey || event.altKey || event.shiftKey ||
                String(event.key || '').toLowerCase() !== 'f') { return; }
            function isEditing(element) {
                return element && (element.isContentEditable ||
                    ['INPUT', 'TEXTAREA', 'SELECT'].indexOf(element.tagName) !== -1);
            }
            const path = typeof event.composedPath === 'function' ? event.composedPath() : [];
            if (isEditing(path[0] || event.target) || isEditing(document.activeElement)) { return; }
            const bridge = window.webkit && window.webkit.messageHandlers &&
                window.webkit.messageHandlers.youtubePlayer;
            if (!bridge) { return; }
            event.preventDefault();
            event.stopImmediatePropagation();
            if (!event.repeat) {
                bridge.postMessage({
                    type: 'TOGGLE_FULLSCREEN',
                    documentGeneration: window.__kasetDocumentGeneration
                });
            }
        }, true);
        """
    }
}
