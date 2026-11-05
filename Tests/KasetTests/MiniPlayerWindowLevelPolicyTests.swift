import AppKit
import Testing
@testable import Kaset

@Suite("Mini player window level policy", .serialized, .tags(.service))
@MainActor
struct MiniPlayerWindowLevelPolicyTests {
    @Test("Unpinned state uses the normal level")
    func unpinnedUsesNormalLevel() {
        #expect(MiniPlayerWindowLevelPolicy.windowLevel(isPinned: false) == .normal)
    }

    @Test("Pinned state uses the floating level")
    func pinnedUsesFloatingLevel() {
        #expect(MiniPlayerWindowLevelPolicy.windowLevel(isPinned: true) == .floating)
    }

    @Test("Collection behavior preserves all-spaces and fullscreen-auxiliary participation")
    func collectionBehaviorPreservesAuxiliaryParticipation() {
        let behavior = MiniPlayerWindowLevelPolicy.collectionBehavior(preserving: [
            .transient,
            .stationary,
            .ignoresCycle,
        ])

        #expect(behavior.contains(.canJoinAllSpaces))
        #expect(behavior.contains(.fullScreenAuxiliary))
        #expect(!behavior.contains(.transient))
        #expect(!behavior.contains(.stationary))
        #expect(!behavior.contains(.ignoresCycle))
    }
}
