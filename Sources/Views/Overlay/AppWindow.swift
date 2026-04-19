@preconcurrency import AVFoundation
import AppKit
import Domain
import Presenters
import SwiftUI

@MainActor
public final class AppWindow: NSWindow {
    private let hostingView: NSHostingView<OverlayContentView>

    public init(
        initialLayout: ScreenLayout,
        headerPresenter: HeaderPresenter,
        lyricsPresenter: LyricsPresenter,
        ripplePresenter: RipplePresenter
    ) {
        let hostingView = NSHostingView(
            rootView: OverlayContentView(
                headerPresenter: headerPresenter,
                lyricsPresenter: lyricsPresenter,
                ripplePresenter: ripplePresenter
            ))
        hostingView.frame = initialLayout.hostingFrame
        self.hostingView = hostingView

        super.init(
            contentRect: initialLayout.windowFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        backgroundColor = .clear
        isOpaque = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        contentView = hostingView

        orderFront(nil)
    }

    public func applyLayout(_ layout: ScreenLayout) {
        setFrame(layout.windowFrame, display: false)
        hostingView.frame = layout.hostingFrame
        if let containerView = contentView, containerView !== hostingView {
            containerView.frame = CGRect(origin: .zero, size: layout.windowFrame.size)
        }
    }

    public func attachPlayerLayer(for player: AVPlayer) {
        backgroundColor = .black

        let containerView = NSView(frame: CGRect(origin: .zero, size: frame.size))
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = containerView.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        playerLayer.videoGravity = .resizeAspectFill
        containerView.wantsLayer = true
        containerView.layer?.addSublayer(playerLayer)
        containerView.addSubview(hostingView)
        contentView = containerView
    }
}
