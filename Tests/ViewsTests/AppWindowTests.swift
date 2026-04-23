import AppKit
import Domain
import Testing

@testable import Views

@MainActor
@Suite("AppWindow")
struct AppWindowTests {
    @Test("overlay defaults expose transparent desktop window styling")
    func overlayDefaults() {
        #expect(AppWindow.overlayLevel.rawValue == Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        #expect(AppWindow.overlayCollectionBehavior.contains(.canJoinAllSpaces))
        #expect(AppWindow.overlayCollectionBehavior.contains(.stationary))
        #expect(AppWindow.overlayCollectionBehavior.contains(.ignoresCycle))
    }

    @Test("content frame matches window size at zero origin")
    func contentFrame() {
        let windowFrame = CGRect(x: 40, y: 30, width: 1024, height: 640)

        #expect(
            AppWindow.contentFrame(for: windowFrame)
                == CGRect(origin: .zero, size: windowFrame.size)
        )
    }

    @Test("content frame handles empty size without crashing")
    func emptyContentFrame() {
        let windowFrame = CGRect(x: 10, y: 20, width: 0, height: 0)

        #expect(AppWindow.contentFrame(for: windowFrame) == .zero)
    }
}
