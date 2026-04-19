import AppKit
import CoreGraphics
import Domain

public struct AppKitScreenProvider {
    public init() {}
}

extension AppKitScreenProvider: ScreenProvider {
    public var screens: [ScreenInfo] {
        NSScreen.screens.map { ScreenInfo(frame: $0.frame, visibleFrame: $0.visibleFrame) }
    }

    public var mainScreen: ScreenInfo? {
        NSScreen.main.map { ScreenInfo(frame: $0.frame, visibleFrame: $0.visibleFrame) }
    }

    public func windowOccupancy(for screen: ScreenInfo) -> Double {
        Self.occupancy(of: screen, windows: visibleWindowBounds())
    }

    /// Pure geometry: sum the area of each window rect intersected with `screen.frame`,
    /// divided by the screen's total area. Extracted for unit testability.
    static func occupancy(of screen: ScreenInfo, windows: [CGRect]) -> Double {
        let screenArea = screen.frame.width * screen.frame.height
        guard screenArea > 0 else { return 1 }
        let covered =
            windows
            .map { $0.intersection(screen.frame) }
            .filter { !$0.isNull && !$0.isEmpty }
            .reduce(0.0) { $0 + $1.width * $1.height }
        return covered / screenArea
    }

    /// Window bounds from `CGWindowListCopyWindowInfo` are in CoreGraphics coordinates
    /// (origin = top-left of primary display, y grows downward), while `NSScreen.frame`
    /// is in AppKit coordinates (origin = bottom-left of primary display, y grows upward).
    /// Convert each rect so the intersection with `screen.frame` is geometrically correct.
    static func cgToAppKit(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    private func visibleWindowBounds() -> [CGRect] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        let myPID = Int(ProcessInfo.processInfo.processIdentifier)
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        return infoList.compactMap { info -> CGRect? in
            guard
                let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                let pid = info[kCGWindowOwnerPID as String] as? Int, pid != myPID,
                let bounds = info[kCGWindowBounds as String] as? NSDictionary
            else { return nil }
            var cgRect = CGRect.zero
            guard CGRectMakeWithDictionaryRepresentation(bounds, &cgRect), cgRect.width > 0, cgRect.height > 0
            else { return nil }
            return Self.cgToAppKit(cgRect, primaryHeight: primaryHeight)
        }
    }
}
