# ADR-0043: YouTube Full Screen in the Main Window

## Status

Accepted

## Context

Entering full screen from the inline YouTube player previously moved playback to
the floating window, then requested native window full screen after a delay.
The main-window presentation needs to preserve the watch route and playback
session while hiding the surrounding interface.

## Decision

Present a full-window video overlay for inline playback. Reparent the existing
watch WebView rather than creating another player or loading the document again.
The floating window retains its existing native full-screen behavior.

Explicit dismissal and pop-out must clear the overlay even immediately after an
enter command. Repeated toggle commands may be throttled; an explicit exit is
never throttled. Full-screen keyboard monitoring is scoped to the hosting key
window and defers to text editing and sheets. Only supported modifier combinations
are consumed, and key repeat does not repeatedly toggle playback or presentation.
WebKit keeps its HTML keyboard handling. An extracted player's DOM listener forwards
F through the existing generation-validated bridge only when neither its event
target nor its active element is editable; interstitials do not forward the key.

Keep media presentation menu actions in `PlayerPresentationCommands`, with
playback state owned by the existing player services.

## Consequences

- Inline full screen does not require an additional playback window or navigation.
- Native macOS window full screen and the full-window video overlay remain distinct.
- The overlay and inline host share one WebView and must not claim it after losing
  ownership during a presentation transition.
- Keyboard routing and service-level exit/pop-out behavior have non-UI regression
  tests. Reparenting and native window transitions still require runtime validation.
