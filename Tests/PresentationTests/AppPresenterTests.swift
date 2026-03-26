import CoreGraphics
import Dependencies
import Domain
import Foundation
import Testing

@testable import Presentation

// MARK: - Stub

private struct StubScreenInteractor: ScreenInteractor {
    var screenSelector: ScreenSelector = .main
    var layoutResult: ScreenLayout = .init()

    func resolveLayout(wallpaperURL: URL?, hasWallpaper: Bool) async -> ScreenLayout { layoutResult }
}

// MARK: - Tests

@Suite("AppPresenter")
struct AppPresenterTests {

    @Suite("resolveFrames")
    struct ResolveFrames {
        @MainActor
        @Test("sets layout and hasWallpaper=true when wallpaperURL is provided")
        func setsLayoutWithWallpaper() async {
            let expectedLayout = ScreenLayout(
                windowFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
                hostingFrame: CGRect(x: 10, y: 10, width: 1900, height: 1060),
                screenOrigin: CGPoint(x: 0, y: 0)
            )

            await withDependencies {
                $0.screenInteractor = StubScreenInteractor(layoutResult: expectedLayout)
            } operation: {
                let presenter = AppPresenter()
                let url = URL(fileURLWithPath: "/tmp/bg.mp4")
                await presenter.resolveFrames(wallpaperURL: url)

                #expect(presenter.hasWallpaper == true)
                #expect(presenter.layout.windowFrame == expectedLayout.windowFrame)
                #expect(presenter.layout.hostingFrame == expectedLayout.hostingFrame)
                #expect(presenter.layout.screenOrigin == expectedLayout.screenOrigin)
            }
        }

        @MainActor
        @Test("sets hasWallpaper=false when wallpaperURL is nil")
        func setsNoWallpaper() async {
            await withDependencies {
                $0.screenInteractor = StubScreenInteractor()
            } operation: {
                let presenter = AppPresenter()
                await presenter.resolveFrames(wallpaperURL: nil)

                #expect(presenter.hasWallpaper == false)
            }
        }

        @MainActor
        @Test("uses default layout when interactor returns default")
        func usesDefaultLayout() async {
            await withDependencies {
                $0.screenInteractor = StubScreenInteractor()
            } operation: {
                let presenter = AppPresenter()
                await presenter.resolveFrames(wallpaperURL: nil)

                #expect(presenter.layout.windowFrame == .zero)
                #expect(presenter.layout.hostingFrame == .zero)
                #expect(presenter.layout.screenOrigin == .zero)
            }
        }
    }
}
