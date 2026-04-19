import Combine
import Dependencies
import Foundation

public protocol WallpaperInteractor: Sendable {
    func resolveWallpaper() async throws -> WallpaperState
    var rippleConfig: RippleStyle { get }
    /// Emits when the system sleeps or wakes (e.g. display asleep/awake).
    /// Provider layer adapts the platform-native notification into a Publisher
    /// so the Presenter stays AppKit-free.
    var systemSleepChanges: AnyPublisher<SleepWakeEvent, Never> { get }
}

public enum WallpaperInteractorKey: TestDependencyKey {
    public static let testValue: any WallpaperInteractor = UnimplementedWallpaperInteractor()
}

extension DependencyValues {
    public var wallpaperInteractor: any WallpaperInteractor {
        get { self[WallpaperInteractorKey.self] }
        set { self[WallpaperInteractorKey.self] = newValue }
    }
}

private struct UnimplementedWallpaperInteractor: WallpaperInteractor {
    func resolveWallpaper() async throws -> WallpaperState {
        WallpaperState()
    }
    var rippleConfig: RippleStyle { .init() }
    var systemSleepChanges: AnyPublisher<SleepWakeEvent, Never> {
        Empty().eraseToAnyPublisher()
    }
}
