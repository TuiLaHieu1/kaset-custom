import Foundation
import Testing
@testable import Kaset

@Suite("Updater service isolation")
@MainActor
struct UpdaterServiceIsolationTests {
    @Test("Updater service is in isolated mode and disables update checks")
    func updaterServiceIsIsolated() {
        let service = UpdaterService()
        #expect(!service.canCheckForUpdates)
        #expect(!service.automaticChecksEnabled)
        #expect(service.lastUpdateCheckDate == nil)
    }

    @Test("Manual checkForUpdates is a safe no-op when isolated")
    func manualCheckIsSafe() {
        let service = UpdaterService()
        // Should not crash, throw, or perform network requests
        service.checkForUpdates()
        #expect(!service.canCheckForUpdates)
    }

    @Test("App configuration has no Sparkle update settings")
    func appConfigurationHasNoSparkleSettings() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // KasetTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // repo root
        let plistURL = root.appendingPathComponent("Info.plist")
        let data = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]

        #expect(plist?["SUFeedURL"] == nil)
        #expect(plist?["SUEnableAutomaticChecks"] == nil)
        #expect(plist?["SUAllowsAutomaticUpdates"] == nil)
        #expect(plist?["SUEnableInstallerLauncherService"] == nil)
    }
}
