import AppKit
import Domain
import Testing

@testable import AppKitScreenProvider

@Suite("AppKitScreenProvider")
struct AppKitScreenProviderTests {
    @MainActor
    @Test("screens mirrors NSScreen.screens")
    func screens() {
        let provider = AppKitScreenProvider()

        #expect(provider.screens.count == NSScreen.screens.count)
        #expect(provider.screens.map(\.frame) == NSScreen.screens.map(\.frame))
    }

    @MainActor
    @Test("mainScreen mirrors NSScreen.main")
    func mainScreen() {
        let provider = AppKitScreenProvider()

        #expect(provider.mainScreen?.frame == NSScreen.main?.frame)
        #expect(provider.mainScreen?.visibleFrame == NSScreen.main?.visibleFrame)
    }
}
