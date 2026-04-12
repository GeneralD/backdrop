import AppKit
import Views

@MainActor
protocol DisplayLinkDriving: AnyObject {
    func start(in window: any AppWindowing)
    func stop()
}

extension DisplayLinkDriver: DisplayLinkDriving {
    func start(in window: any AppWindowing) {
        guard let window = window as? NSWindow else {
            assertionFailure("DisplayLinkDriver requires an NSWindow-backed AppWindowing")
            return
        }
        start(in: window)
    }
}
