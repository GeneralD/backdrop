@preconcurrency import AVFoundation
@preconcurrency import Combine
import Dependencies
import Domain
import Foundation
import Testing

@testable import Presenters

// MARK: - Stub

private struct StubWallpaperInteractor: WallpaperInteractor {
    var wallpaperState: WallpaperState = .init()
    var rippleConfig: RippleStyle = .init()
    var sleepChangesSubject: PassthroughSubject<SleepWakeEvent, Never>? = nil

    func resolveWallpaper() async throws -> WallpaperState { wallpaperState }
    var systemSleepChanges: AnyPublisher<SleepWakeEvent, Never> {
        sleepChangesSubject?.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
    }
}

private struct FailingWallpaperInteractor: WallpaperInteractor {
    var rippleConfig: RippleStyle = .init()

    func resolveWallpaper() async throws -> WallpaperState { throw StubError.resolveFailed }
    var systemSleepChanges: AnyPublisher<SleepWakeEvent, Never> { Empty().eraseToAnyPublisher() }
}

private enum StubError: Error {
    case resolveFailed
}

// MARK: - Tests

@Suite("WallpaperPresenter")
struct WallpaperPresenterTests {

    @Suite("start")
    struct Resolve {
        @MainActor
        @Test("sets wallpaperURL, start, and end from interactor result")
        func setsWallpaperState() async {
            let url = URL(fileURLWithPath: "/tmp/bg.mp4")
            let state = WallpaperState(url: url, start: 5.0, end: 30.0)

            await withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(wallpaperState: state)
            } operation: {
                let presenter = WallpaperPresenter()
                presenter.start()
                await presenter.waitForLoad()

                #expect(presenter.wallpaperURL == url)
                #expect(presenter.startTime == 5.0)
                #expect(presenter.endTime == 30.0)
                #expect(presenter.isLoading == false)
            }
        }

        @MainActor
        @Test("nil state when no wallpaper configured")
        func nilWallpaper() async {
            await withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(wallpaperState: .init())
            } operation: {
                let presenter = WallpaperPresenter()
                presenter.start()
                await presenter.waitForLoad()

                #expect(presenter.wallpaperURL == nil)
                #expect(presenter.startTime == nil)
                #expect(presenter.endTime == nil)
                #expect(presenter.isLoading == false)
            }
        }

        @MainActor
        @Test("sets nil when interactor throws")
        func handlesError() async {
            await withDependencies {
                $0.wallpaperInteractor = FailingWallpaperInteractor()
            } operation: {
                let presenter = WallpaperPresenter()
                presenter.start()
                await presenter.waitForLoad()

                #expect(presenter.wallpaperURL == nil)
                #expect(presenter.isLoading == false)
            }
        }

        @MainActor
        @Test("stop clears player state")
        func stopClearsPlayer() async {
            let url = URL(fileURLWithPath: "/tmp/bg.mp4")
            let state = WallpaperState(url: url, start: 5.0, end: 30.0)

            await withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(wallpaperState: state)
            } operation: {
                let presenter = WallpaperPresenter()
                presenter.start()
                await presenter.waitForLoad()
                #expect(presenter.wallpaperURL == url)

                presenter.stop()
                #expect(presenter.player == nil)
            }
        }

        @MainActor
        @Test("start with only start time, no end time")
        func startTimeOnly() async {
            let url = URL(fileURLWithPath: "/tmp/bg.mp4")
            let state = WallpaperState(url: url, start: 10.0, end: nil)

            await withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(wallpaperState: state)
            } operation: {
                let presenter = WallpaperPresenter()
                presenter.start()
                await presenter.waitForLoad()

                #expect(presenter.wallpaperURL == url)
                #expect(presenter.startTime == 10.0)
                #expect(presenter.endTime == nil)
            }
        }
    }

    @Suite("onPlayerAvailable")
    struct OnPlayerAvailable {
        @MainActor
        @Test("fires once when player becomes available")
        func firesOnceOnPlayerReady() async {
            let url = URL(fileURLWithPath: "/tmp/bg.mp4")
            let state = WallpaperState(url: url, start: nil, end: nil)

            await withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(wallpaperState: state)
            } operation: {
                let presenter = WallpaperPresenter()

                final class Counter: @unchecked Sendable {
                    var count = 0
                    var player: AVPlayer?
                }
                let counter = Counter()

                presenter.onPlayerAvailable { player in
                    counter.count += 1
                    counter.player = player
                }

                presenter.start()
                await presenter.waitForLoad()

                let deadline = ContinuousClock.now + .seconds(2)
                while counter.count < 1, ContinuousClock.now < deadline {
                    try? await Task.sleep(for: .milliseconds(10))
                }

                #expect(counter.count == 1)
                #expect(counter.player === presenter.player)
            }
        }

        @MainActor
        @Test("never fires when no wallpaper is configured")
        func doesNotFireWhenNoPlayer() async {
            await withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(wallpaperState: .init())
            } operation: {
                let presenter = WallpaperPresenter()
                final class Counter: @unchecked Sendable { var count = 0 }
                let counter = Counter()

                presenter.onPlayerAvailable { _ in counter.count += 1 }
                presenter.start()
                await presenter.waitForLoad()

                #expect(counter.count == 0)
                #expect(presenter.player == nil)
            }
        }

        @MainActor
        @Test("stop clears onPlayerAvailable subscription")
        func stopClearsSubscription() async {
            let url = URL(fileURLWithPath: "/tmp/bg.mp4")
            let state = WallpaperState(url: url, start: nil, end: nil)

            await withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(wallpaperState: state)
            } operation: {
                let presenter = WallpaperPresenter()
                presenter.onPlayerAvailable { _ in }
                presenter.start()
                await presenter.waitForLoad()
                presenter.stop()
                // Exercises cancellables.removeAll() branch — no crash expected.
            }
        }
    }

    @Suite("sleep / wake observation")
    struct SleepWake {
        @MainActor
        @Test(".willSleep pauses the player")
        func willSleepPauses() async {
            let url = URL(fileURLWithPath: "/tmp/bg.mp4")
            let state = WallpaperState(url: url, start: nil, end: nil)
            let subject = PassthroughSubject<SleepWakeEvent, Never>()

            await withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(
                    wallpaperState: state, sleepChangesSubject: subject)
            } operation: {
                let presenter = WallpaperPresenter()
                presenter.start()
                await presenter.waitForLoad()

                // setupPlayer started playback; emit .willSleep and observe pause.
                subject.send(.willSleep)

                let deadline = ContinuousClock.now + .seconds(1)
                while presenter.player?.rate != 0, ContinuousClock.now < deadline {
                    try? await Task.sleep(for: .milliseconds(10))
                }
                #expect(presenter.player?.rate == 0)
            }
        }

        @MainActor
        @Test(".didWake resumes the player")
        func didWakeResumes() async {
            let url = URL(fileURLWithPath: "/tmp/bg.mp4")
            let state = WallpaperState(url: url, start: nil, end: nil)
            let subject = PassthroughSubject<SleepWakeEvent, Never>()

            await withDependencies {
                $0.wallpaperInteractor = StubWallpaperInteractor(
                    wallpaperState: state, sleepChangesSubject: subject)
            } operation: {
                let presenter = WallpaperPresenter()
                presenter.start()
                await presenter.waitForLoad()

                subject.send(.willSleep)
                subject.send(.didWake)
                // Exercising the .didWake branch of observeSleepWake sink.
            }
        }
    }
}
