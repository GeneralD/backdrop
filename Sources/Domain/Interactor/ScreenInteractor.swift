import Combine
import Dependencies

public protocol ScreenInteractor: Sendable {
    var screenSelector: ScreenSelector { get }
    var screenDebounce: Double { get }
    func resolveLayout() -> ScreenLayout
    /// Emits when the system's screen configuration changes
    /// (e.g. a display is connected, disconnected, or reconfigured).
    /// Provider layer adapts the platform-native notification into a Publisher
    /// so the Presenter stays AppKit-free.
    var screenChanges: AnyPublisher<Void, Never> { get }
}

public enum ScreenInteractorKey: TestDependencyKey {
    public static let testValue: any ScreenInteractor = UnimplementedScreenInteractor()
}

extension DependencyValues {
    public var screenInteractor: any ScreenInteractor {
        get { self[ScreenInteractorKey.self] }
        set { self[ScreenInteractorKey.self] = newValue }
    }
}

private struct UnimplementedScreenInteractor: ScreenInteractor {
    var screenSelector: ScreenSelector { .main }
    var screenDebounce: Double { 5 }
    func resolveLayout() -> ScreenLayout { .init() }
    var screenChanges: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
}
