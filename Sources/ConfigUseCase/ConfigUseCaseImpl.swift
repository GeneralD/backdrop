import Dependencies
import Domain

public struct ConfigUseCaseImpl {
    @Dependency(\.configRepository) private var repository

    public init() {}
}

extension ConfigUseCaseImpl: ConfigUseCase {
    public func loadAppStyle() -> AppStyle {
        repository.loadAppStyle()
    }

    public func template(format: ConfigFormat) -> String? {
        repository.template(format: format)
    }

    public func writeTemplate(format: ConfigFormat, force: Bool) throws -> String {
        try repository.writeTemplate(format: format, force: force)
    }
}
