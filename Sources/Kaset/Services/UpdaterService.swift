import Foundation
import Sparkle

// MARK: - UpdaterService

/// Manages application updates via Sparkle framework.
///
/// For Kaset Custom, automatic update checks are disabled and isolated from
/// upstream repositories to prevent overwriting custom features.
@MainActor
@Observable
final class UpdaterService {
    /// The Sparkle updater controller that manages the update lifecycle.
    private let updaterController: SPUStandardUpdaterController

    /// Whether automatic update checks are enabled.
    ///
    /// Disabled for Kaset Custom to prevent unauthorized background update checks.
    var automaticChecksEnabled: Bool {
        get { false }
        set { /* No-op while updates are isolated */ }
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
    ///
    /// `startingUpdater` is set to `false` to ensure no background network requests
    /// or checks occur on application launch.
    init() {
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        DiagnosticsLogger.updater.info("UpdaterService initialized in isolated mode")
    }

    /// Manually triggers an update check.
    ///
    /// Guarded to ensure no network calls or downloads take place while in isolated mode.
    func checkForUpdates() {
        guard self.canCheckForUpdates else {
            DiagnosticsLogger.updater.info("Manual update check ignored: Kaset Custom updater is isolated")
            return
        }
        self.updaterController.checkForUpdates(nil)
    }
}
