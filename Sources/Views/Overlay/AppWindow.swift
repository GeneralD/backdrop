@preconcurrency import AVFoundation
import AppKit
import Domain
import Presenters
import SwiftUI

@MainActor
public final class AppWindow: NSWindow {
    static var overlayLevel: NSWindow.Level {
        .init(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
    }

    static var overlayCollectionBehavior: NSWindow.CollectionBehavior {
        [.canJoinAllSpaces, .stationary, .ignoresCycle]
    }

    static func contentFrame(for windowFrame: CGRect) -> CGRect {
        CGRect(origin: .zero, size: windowFrame.size)
    }

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

        level = Self.overlayLevel
        backgroundColor = .clear
        isOpaque = false
        ignoresMouseEvents = true
        collectionBehavior = Self.overlayCollectionBehavior

        contentView = hostingView
    }

    public func show() {
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

        let containerView = NSView(frame: Self.contentFrame(for: frame))
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
