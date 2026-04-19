@preconcurrency import AVFoundation
import Domain
import Views

@MainActor
protocol OverlayWindow: AnyObject {
    func applyLayout(_ layout: ScreenLayout)
    func attachPlayerLayer(for player: AVPlayer)
    func orderOut(_ sender: Any?)
    func close()
}

extension AppWindow: OverlayWindow {}
