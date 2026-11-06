# ADR-0042: Manual Updates for Personal Builds

## Status

Accepted

## Context

Kaset is maintained as a personal build. Sparkle adds a framework, installer
entitlements, signing steps, and appcast release tooling that are not needed for
this distribution model.

## Decision

Remove Sparkle and its release infrastructure. `UpdaterService` remains as a
stable, disabled interface so existing settings and commands are safe no-ops.
Updates are installed by pulling the local Git checkout and building a new app.

## Consequences

- Packaged apps have no updater framework or Sparkle-specific sandbox exceptions.
- Release verification checks the app's signing and App Intents metadata only.
- A future public distribution needs a new update strategy and ADR before an
  automatic updater is reintroduced.
