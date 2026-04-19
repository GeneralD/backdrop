import AppKit
import Combine
import Dependencies
import Domain
import Foundation
import Testing

@testable import WallpaperInteractor

private struct StubConfigUseCase: ConfigUseCase, Sendable {
    var style: AppStyle = .init()
    var appStyle: AppStyle { style }
    func template(format: ConfigFormat) -> String? { nil }
    func writeTemplate(format: ConfigFormat, force: Bool) throws -> String { "" }
    var existingConfigPath: String? { nil }
}

private struct StubWallpaperUseCase: WallpaperUseCase, Sendable {
    var result: URL?

    func resolveWallpaper(value: String?, configDir: String) async throws -> URL? {
        result
    }
}

@Suite("WallpaperInteractor")
struct WallpaperInteractorImplTests {

    @Test("resolveWallpaper returns empty state when no wallpaper configured")
    func noWallpaperConfig() async throws {
        let interactor = withDependencies {
            $0.configUseCase = StubConfigUseCase()
            $0.wallpaperUseCase = StubWallpaperUseCase()
        } operation: {
            WallpaperInteractorImpl()
        }

        let state = try await interactor.resolveWallpaper()
        #expect(state.url == nil)
        #expect(state.start == nil)
        #expect(state.end == nil)
    }

    @Test("resolveWallpaper returns state with URL when wallpaper configured")
    func withWallpaperConfig() async throws {
        let wallpaper = WallpaperStyle(location: "bg.mp4", start: 10, end: 180)
        let style = AppStyle(wallpaper: wallpaper, configDir: "/config")
        let resolved = URL(fileURLWithPath: "/resolved/bg.mp4")
        let interactor = withDependencies {
            $0.configUseCase = StubConfigUseCase(style: style)
            $0.wallpaperUseCase = StubWallpaperUseCase(result: resolved)
        } operation: {
            WallpaperInteractorImpl()
        }

        let state = try await interactor.resolveWallpaper()
        #expect(state.url == resolved)
        #expect(state.start == 10)
        #expect(state.end == 180)
    }

    @Test("resolveWallpaper uses home directory when configDir is nil")
    func configDirFallback() async throws {
        let wallpaper = WallpaperStyle(location: "bg.mp4")
        let style = AppStyle(wallpaper: wallpaper, configDir: nil)
        let interactor = withDependencies {
            $0.configUseCase = StubConfigUseCase(style: style)
            $0.wallpaperUseCase = StubWallpaperUseCase(result: URL(fileURLWithPath: "/bg.mp4"))
        } operation: {
            WallpaperInteractorImpl()
        }

        let state = try await interactor.resolveWallpaper()
        #expect(state.url != nil)
    }

    @Test("rippleConfig returns config from appStyle")
    func rippleConfigFromAppStyle() {
        let style = AppStyle(ripple: RippleStyle(enabled: true, idle: 3.0))
        let interactor = withDependencies {
            $0.configUseCase = StubConfigUseCase(style: style)
            $0.wallpaperUseCase = StubWallpaperUseCase()
        } operation: {
            WallpaperInteractorImpl()
        }

        #expect(interactor.rippleConfig.enabled == true)
        #expect(interactor.rippleConfig.idle == 3.0)
    }

    @Test("systemSleepChanges emits .willSleep on NSWorkspace sleep notification")
    func emitsWillSleep() async {
        let interactor = withDependencies {
            $0.configUseCase = StubConfigUseCase()
            $0.wallpaperUseCase = StubWallpaperUseCase()
        } operation: {
            WallpaperInteractorImpl()
        }

        final class Collector: @unchecked Sendable { var events: [SleepWakeEvent] = [] }
        let collector = Collector()
        let cancellable = interactor.systemSleepChanges.sink { collector.events.append($0) }

        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.screensDidSleepNotification, object: nil)

        let deadline = ContinuousClock.now + .seconds(1)
        while collector.events.isEmpty, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(collector.events.contains(.willSleep))
        cancellable.cancel()
    }

    @Test("systemSleepChanges emits .didWake on NSWorkspace wake notification")
    func emitsDidWake() async {
        let interactor = withDependencies {
            $0.configUseCase = StubConfigUseCase()
            $0.wallpaperUseCase = StubWallpaperUseCase()
        } operation: {
            WallpaperInteractorImpl()
        }

        final class Collector: @unchecked Sendable { var events: [SleepWakeEvent] = [] }
        let collector = Collector()
        let cancellable = interactor.systemSleepChanges.sink { collector.events.append($0) }

        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.screensDidWakeNotification, object: nil)

        let deadline = ContinuousClock.now + .seconds(1)
        while collector.events.isEmpty, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(collector.events.contains(.didWake))
        cancellable.cancel()
    }
}
