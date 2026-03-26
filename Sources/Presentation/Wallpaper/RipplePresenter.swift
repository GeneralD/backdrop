import Dependencies
import Domain
import Foundation

@MainActor
public final class RipplePresenter: ObservableObject {
    @Published public private(set) var rippleCenter: CGPoint = .zero
    @Published public private(set) var rippleProgress: Double = 0
    @Published public private(set) var isActive: Bool = false

    private var idleTimer: TimeInterval = 0
    private var idleThreshold: TimeInterval = 1.0

    @Dependency(\.configUseCase) private var configService

    public init() {}

    public var isEnabled: Bool { configService.loadAppStyle().ripple.enabled }

    public func start() {
        idleThreshold = configService.loadAppStyle().ripple.idle
    }

    public func update(screenPoint: CGPoint) {
        rippleCenter = screenPoint
        rippleProgress = 0
        isActive = true
        idleTimer = 0
    }

    public func idle() {
        guard isActive else { return }
        idleTimer += 1.0 / 60.0
        guard idleTimer >= idleThreshold else { return }
        isActive = false
    }
}
