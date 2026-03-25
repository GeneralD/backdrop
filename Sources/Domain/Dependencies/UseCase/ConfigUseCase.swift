import Dependencies

public protocol ConfigUseCase: Sendable {
    @MainActor func loadAppStyle() -> AppStyle
    func template(format: ConfigFormat) -> String?
    func writeTemplate(format: ConfigFormat, force: Bool) throws -> String
}

public enum ConfigUseCaseKey: TestDependencyKey {
    public static let testValue: any ConfigUseCase = UnimplementedConfigUseCase()
}

extension DependencyValues {
    public var configUseCase: any ConfigUseCase {
        get { self[ConfigUseCaseKey.self] }
        set { self[ConfigUseCaseKey.self] = newValue }
    }
}

private struct UnimplementedConfigUseCase: ConfigUseCase {
    @MainActor func loadAppStyle() -> AppStyle { .init() }
    func template(format: ConfigFormat) -> String? { nil }
    func writeTemplate(format: ConfigFormat, force: Bool) throws -> String { "" }
}
