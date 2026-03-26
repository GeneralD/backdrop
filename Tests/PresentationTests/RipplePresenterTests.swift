import Dependencies
import Domain
import Foundation
import Testing

@testable import Presentation

// MARK: - Stub

private struct StubWallpaperInteractor: WallpaperInteractor {
    var rippleConfig: RippleStyle = .init()

    func resolveWallpaper() async throws -> WallpaperState { .init() }
}

// MARK: - Tests

@Suite("RipplePresenter")
struct RipplePresenterTests {

    @Suite("isEnabled")
    struct IsEnabled {
        @MainActor
        @Test("reflects interactor config when enabled")
        func enabledReflectsConfig() {
            withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(rippleConfig: .init(enabled: true))
            } operation: {
                let presenter = RipplePresenter()
                #expect(presenter.isEnabled == true)
            }
        }

        @MainActor
        @Test("reflects interactor config when disabled")
        func disabledReflectsConfig() {
            withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(rippleConfig: .init(enabled: false))
            } operation: {
                let presenter = RipplePresenter()
                #expect(presenter.isEnabled == false)
            }
        }
    }

    @Suite("start")
    struct Start {
        @MainActor
        @Test("sets idleThreshold from interactor ripple config")
        func setsIdleThreshold() {
            withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(rippleConfig: .init(idle: 2.5))
            } operation: {
                let presenter = RipplePresenter()
                presenter.start()

                // After start, update and idle behavior should respect the threshold.
                // First activate via update, then verify idle respects threshold.
                presenter.update(screenPoint: .zero)
                #expect(presenter.isActive == true)

                // One tick at 1/60s should not deactivate (threshold=2.5)
                presenter.idle()
                #expect(presenter.isActive == true)
            }
        }
    }

    @Suite("update")
    struct Update {
        @MainActor
        @Test("sets isActive to true and updates rippleCenter")
        func updateActivates() {
            withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor()
            } operation: {
                let presenter = RipplePresenter()
                presenter.start()
                presenter.update(screenPoint: CGPoint(x: 100, y: 200))

                #expect(presenter.isActive == true)
                #expect(presenter.rippleCenter == CGPoint(x: 100, y: 200))
                #expect(presenter.rippleProgress == 0)
            }
        }
    }

    @Suite("idle")
    struct Idle {
        @MainActor
        @Test("deactivates after enough idle ticks exceed threshold")
        func idleDeactivatesAfterThreshold() {
            withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(rippleConfig: .init(idle: 0.05))
            } operation: {
                let presenter = RipplePresenter()
                presenter.start()
                presenter.update(screenPoint: .zero)
                #expect(presenter.isActive == true)

                // Each idle() increments by 1/60 ≈ 0.0167s. Need ~3 ticks to exceed 0.05s.
                presenter.idle()
                presenter.idle()
                presenter.idle()
                presenter.idle()

                #expect(presenter.isActive == false)
            }
        }

        @MainActor
        @Test("does not deactivate before threshold is reached")
        func idleStaysActiveBeforeThreshold() {
            withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(rippleConfig: .init(idle: 1.0))
            } operation: {
                let presenter = RipplePresenter()
                presenter.start()
                presenter.update(screenPoint: .zero)

                // Single tick is far from 1.0 threshold
                presenter.idle()
                #expect(presenter.isActive == true)
            }
        }

        @MainActor
        @Test("does nothing when already inactive")
        func idleWhenInactive() {
            withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor()
            } operation: {
                let presenter = RipplePresenter()
                presenter.start()

                // Never activated, so idle should be a no-op
                presenter.idle()
                #expect(presenter.isActive == false)
            }
        }
    }
}
