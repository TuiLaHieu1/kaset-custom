import Foundation
@testable import Kaset
import Testing

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

    @Test("App configuration isolates feed URL and disables automatic checks")
    func appConfigurationIsIsolated() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // KasetTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // repo root
        let plistURL = root.appendingPathComponent("Info.plist")
        let data = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]

        let feedURL = plist?["SUFeedURL"] as? String
        #expect(feedURL == "https://raw.githubusercontent.com/TuiLaHieu1/kaset-custom/main/appcast.xml")
        #expect(feedURL?.contains("sozercan/kaset") == false)

        let autoChecks = plist?["SUEnableAutomaticChecks"] as? Bool
        #expect(autoChecks == false)

        let autoUpdates = plist?["SUAllowsAutomaticUpdates"] as? Bool
        #expect(autoUpdates == false)

        let publicEDKey = plist?["SUPublicEDKey"] as? String
        #expect(publicEDKey == nil)
    }
}
