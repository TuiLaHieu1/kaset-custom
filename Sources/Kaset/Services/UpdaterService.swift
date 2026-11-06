import Foundation

// MARK: - UpdaterService

/// Manages application updates.
///
/// For Kaset Custom, updates are managed manually via Git / local builds
/// without external updater frameworks.
@MainActor
@Observable
final class UpdaterService {
    /// Whether automatic update checks are enabled.
    ///
    /// Disabled for Kaset Custom to prevent unauthorized background update checks.
    var automaticChecksEnabled: Bool {
        get { false }
        set {
            _ = newValue
        }
    }

    /// Whether the updater can currently check for updates.
    ///
    /// Always returns `false` while isolated so that UI controls (menu items, buttons)
    /// remain safely disabled and cannot initiate downloads from upstream.
    var canCheckForUpdates: Bool {
        false
    }

    /// The date of the last update check, or `nil` if never checked.
    var lastUpdateCheckDate: Date? {
        nil
    }

    /// Initializes the updater service in isolated mode.
    init() {
        DiagnosticsLogger.updater.info("UpdaterService initialized in isolated mode (zero-dependency)")
    }

    /// Manually triggers an update check.
    ///
    /// Guarded to ensure no network calls or downloads take place while in isolated mode.
    func checkForUpdates() {
        guard self.canCheckForUpdates else {
            DiagnosticsLogger.updater.info("Manual update check ignored: Kaset Custom updater is isolated")
            return
        }
    }
}
