import AppKit
import Views

@MainActor
protocol FrameScheduler: AnyObject {
    func start(in window: any OverlayWindow)
    func stop()
}

extension DisplayLinkDriver: FrameScheduler {
    func start(in window: any OverlayWindow) {
        guard let window = window as? NSWindow else {
            assertionFailure("DisplayLinkDriver requires an NSWindow-backed OverlayWindow")
            return
        }
        start(in: window)
    }
}
