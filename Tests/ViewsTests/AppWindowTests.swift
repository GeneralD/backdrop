@preconcurrency import AVFoundation
import AppKit
import Domain
import Presenters
import Testing

@testable import Views

@MainActor
@Suite("AppWindow")
struct AppWindowTests {
    @Test("init configures a transparent desktop overlay window")
    func initConfiguresOverlayWindow() {
        let layout = ScreenLayout(
            windowFrame: CGRect(x: 0, y: 0, width: 1280, height: 720),
            hostingFrame: CGRect(x: 16, y: 24, width: 1248, height: 680),
            screenOrigin: .zero
        )
        let window = makeWindow(initialLayout: layout)
        defer { close(window) }

        #expect(window.frame == layout.windowFrame)
        #expect(window.contentView?.frame == CGRect(origin: .zero, size: layout.windowFrame.size))
        #expect(window.isOpaque == false)
        #expect(window.ignoresMouseEvents)
        #expect(window.backgroundColor?.alphaComponent == 0)
        #expect(window.collectionBehavior.contains(.canJoinAllSpaces))
        #expect(window.collectionBehavior.contains(.stationary))
        #expect(window.collectionBehavior.contains(.ignoresCycle))
        #expect(window.level.rawValue == Int(CGWindowLevelForKey(.desktopWindow)) + 1)
    }

    @Test("attachPlayerLayer wraps the hosting view in a player-backed container")
    func attachPlayerLayerWrapsContent() {
        let layout = ScreenLayout(
            windowFrame: CGRect(x: 0, y: 0, width: 800, height: 500),
            hostingFrame: CGRect(x: 0, y: 0, width: 800, height: 500),
            screenOrigin: .zero
        )
        let window = makeWindow(initialLayout: layout)
        defer { close(window) }

        let player = AVPlayer()
        window.attachPlayerLayer(for: player)

        let containerView = window.contentView
        let playerLayer = containerView?.layer?.sublayers?.first as? AVPlayerLayer

        #expect(window.backgroundColor == .black)
        #expect(containerView?.subviews.count == 1)
        #expect(playerLayer?.player === player)
        #expect(playerLayer?.videoGravity == .resizeAspectFill)
        #expect(playerLayer?.autoresizingMask == [.layerWidthSizable, .layerHeightSizable])
    }

    @Test("applyLayout updates both the window frame and player container")
    func applyLayoutUpdatesPlayerContainer() {
        let initialLayout = ScreenLayout(
            windowFrame: CGRect(x: 0, y: 0, width: 800, height: 500),
            hostingFrame: CGRect(x: 0, y: 0, width: 800, height: 500),
            screenOrigin: .zero
        )
        let updatedLayout = ScreenLayout(
            windowFrame: CGRect(x: 40, y: 30, width: 1024, height: 640),
            hostingFrame: CGRect(x: 24, y: 32, width: 960, height: 576),
            screenOrigin: CGPoint(x: 40, y: 30)
        )
        let window = makeWindow(initialLayout: initialLayout)
        defer { close(window) }

        window.attachPlayerLayer(for: AVPlayer())
        window.applyLayout(updatedLayout)

        #expect(window.frame == updatedLayout.windowFrame)
        #expect(window.contentView?.frame == CGRect(origin: .zero, size: updatedLayout.windowFrame.size))
        #expect(window.contentView?.subviews.first?.frame == updatedLayout.hostingFrame)
    }

    private func makeWindow(initialLayout: ScreenLayout) -> AppWindow {
        AppWindow(
            initialLayout: initialLayout,
            headerPresenter: HeaderPresenter(),
            lyricsPresenter: LyricsPresenter(),
            ripplePresenter: RipplePresenter()
        )
    }

    private func close(_ window: AppWindow) {
        window.orderOut(nil)
        window.close()
    }
}
