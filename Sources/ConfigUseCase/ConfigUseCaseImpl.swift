import Dependencies
import Domain
import ConfigRepository

public struct ConfigUseCaseImpl {
    public init() {}
}

extension ConfigUseCaseImpl: ConfigUseCase {
    @MainActor
    public func loadAppStyle() -> AppStyle {
        ConfigRepositoryImpl().loadAppStyle()
    }
}

extension ConfigUseCaseKey: DependencyKey {
    public static let liveValue: any ConfigUseCase = ConfigUseCaseImpl()
}
