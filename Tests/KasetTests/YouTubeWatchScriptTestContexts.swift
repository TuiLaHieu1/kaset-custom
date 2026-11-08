import Foundation
import JavaScriptCore
import Testing
@testable import Kaset

extension YouTubeWatchScriptTests {
    func makeObserverContext(paused: Bool) throws -> JSContext {
        let context = try #require(JSContext())
        try self.evaluate(
            """
            var postedMessages = [];
            var intervalCalls = [];
            var timeoutCalls = [];
            var now = 1000;
            Date.now = function() { return now; };

            function setInterval(callback, milliseconds) {
                intervalCalls.push({ callback: callback, milliseconds: milliseconds });
                return intervalCalls.length;
            }
            function clearInterval(id) {}
            function setTimeout(callback, milliseconds) {
                timeoutCalls.push({ callback: callback, milliseconds: milliseconds });
                return timeoutCalls.length;
            }
            function clearTimeout(id) {}

            var window = {
                webkit: {
                    messageHandlers: {
                        youtubePlayer: {
                            postMessage: function(message) { postedMessages.push(message); }
                        }
                    }
                }
            };
            var console = { log: function() {} };

            var videoListeners = {};
            var video = {
                paused: \(paused ? "true" : "false"),
                ended: false,
                currentTime: 12,
                duration: 120,
                readyState: 4,
                muted: false,
                volume: 1,
                addEventListener: function(name, handler) {
                    if (!videoListeners[name]) { videoListeners[name] = []; }
                    videoListeners[name].push(handler);
                }
            };
            function fireVideoEvent(name) {
                (videoListeners[name] || []).forEach(function(handler) { handler(); });
            }

            var moviePlayer = {
                classList: { contains: function() { return false; } },
                getPresentingPlayerType: function() { return 1; }, addEventListener: function() {},
                getVideoData: function() { return { video_id: 'abc123', title: 'Test Video' }; },
                unMute: function() {}
            };
            var documentListeners = {};
            var document = {
                title: 'Test Video - YouTube',
                readyState: 'complete',
                body: {},
                documentElement: {},
                getElementById: function(id) { return id === 'movie_player' ? moviePlayer : null; },
                querySelector: function(selector) {
                    if (selector === '#movie_player video' || selector === 'video') { return video; }
                    if (selector === '.ytp-autonav-toggle-button') { return null; }
                    return null;
                },
                addEventListener: function(name, handler) { documentListeners[name] = handler; }
            };
            var mutationCallbacks = [];
            function MutationObserver(callback) {
                this.callback = callback;
                mutationCallbacks.push(callback);
            }
            MutationObserver.prototype.observe = function() {};
            MutationObserver.prototype.disconnect = function() {};
            """,
            in: context
        )
        return context
    }

    func makeExtractionContext() throws -> JSContext {
        let context = try #require(JSContext())
        try self.evaluate(
            """
            var window = {};
            var console = { log: function() {} };

            function makeElement(name, parent) {
                var element = { name: name, parentElement: parent, classes: {}, id: '', textContent: '' };
                element.classList = {
                    add: function(value) { element.classes[value] = true; },
                    remove: function(value) { delete element.classes[value]; },
                    contains: function(value) { return !!element.classes[value]; }
                };
                return element;
            }

            var elementsById = {};
            var html = makeElement('html', null);
            var body = makeElement('body', html);
            var player = makeElement('movie_player', body);
            var video = makeElement('video', player);
            var allElements = [html, body, player, video];

            var document = {
                documentElement: html,
                body: body,
                head: {
                    appendChild: function(element) {
                        if (element.id) { elementsById[element.id] = element; }
                    }
                },
                createElement: function(name) {
                    var element = makeElement(name, null);
                    return element;
                },
                getElementById: function(id) { return elementsById[id] || null; },
                querySelector: function(selector) {
                    if (selector === '#movie_player video' || selector === 'video') { return video; }
                    return null;
                },
                querySelectorAll: function(selector) {
                    if (selector !== '.kaset-visible') { return []; }
                    return allElements.filter(function(element) {
                        return element.classList.contains('kaset-visible');
                    });
                }
            };

            var mutationCallbacks = [];
            function MutationObserver(callback) {
                this.callback = callback;
                mutationCallbacks.push(callback);
            }
            MutationObserver.prototype.observe = function() {};
            MutationObserver.prototype.disconnect = function() {};

            var rafQueue = [];
            var rafScheduledCount = 0;
            function requestAnimationFrame(callback) {
                rafScheduledCount += 1;
                rafQueue.push(callback);
                return rafScheduledCount;
            }
            function drainAnimationFrames(limit) {
                var ran = 0;
                while (rafQueue.length && ran < limit) {
                    var callback = rafQueue.shift();
                    callback();
                    ran += 1;
                }
                return ran;
            }
            """,
            in: context
        )
        return context
    }

    func evaluate(_ script: String, in context: JSContext) throws {
        context.exception = nil
        _ = context.evaluateScript(script)
        if let exception = context.exception?.toString() {
            Issue.record("JavaScript exception: \(exception)")
            throw TestScriptError.javaScriptException(exception)
        }
    }
}

// MARK: - TestScriptError

private enum TestScriptError: Error {
    case javaScriptException(String)
}
