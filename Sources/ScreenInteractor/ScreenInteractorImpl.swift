import CoreGraphics
import Dependencies
import Domain

public struct ScreenInteractorImpl {
    @Dependency(\.configUseCase) private var configService
    @Dependency(\.screenProvider) private var screenProvider

    public init() {}
}

extension ScreenInteractorImpl: ScreenInteractor {
    public var screenSelector: ScreenSelector {
        configService.appStyle.screen
    }

    public var screenDebounce: Double {
        configService.appStyle.screenDebounce
    }

    public func resolveLayout() -> ScreenLayout {
        guard let screen = resolveScreen() else { return .init() }

        let fullFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let hostingFrame = CGRect(
            x: visibleFrame.minX - fullFrame.minX,
            y: visibleFrame.minY - fullFrame.minY,
            width: visibleFrame.width,
            height: visibleFrame.height
        )
        return ScreenLayout(
            windowFrame: fullFrame,
            hostingFrame: hostingFrame,
            screenOrigin: CGPoint(x: visibleFrame.minX, y: visibleFrame.minY)
        )
    }

    private func resolveScreen() -> ScreenInfo? {
        let screens = screenProvider.screens
        guard let fallback = screens.first else { return nil }
        switch screenSelector {
        case .main:
            return screenProvider.mainScreen ?? fallback
        case .primary:
            return fallback
        case .index(let n):
            return screens.indices.contains(n) ? screens[n] : fallback
        case .smallest:
            return screens.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
                ?? fallback
        case .largest:
            return screens.max { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
                ?? fallback
        case .vacant:
            return mostVacantScreen(among: screens) ?? fallback
        }
    }

    private func mostVacantScreen(among screens: [ScreenInfo]) -> ScreenInfo? {
        let windowBounds = screenProvider.visibleWindowBounds
        return screens.min { occupancy($0, windowBounds: windowBounds) < occupancy($1, windowBounds: windowBounds) }
    }

    private func occupancy(_ screen: ScreenInfo, windowBounds: [CGRect]) -> Double {
        let screenArea = screen.frame.width * screen.frame.height
        guard screenArea > 0 else { return 1 }
        let coveredArea =
            windowBounds
            .compactMap { $0.intersection(screen.frame) }
            .filter { !$0.isNull && !$0.isEmpty }
            .reduce(0.0) { $0 + $1.width * $1.height }
        return coveredArea / screenArea
    }
}
