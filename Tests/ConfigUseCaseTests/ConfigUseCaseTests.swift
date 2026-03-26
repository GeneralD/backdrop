import Dependencies
import Domain
import Foundation
import Testing

@testable import ConfigUseCase

@Suite("ConfigUseCase")
struct ConfigUseCaseTests {
    @Test("appStyle delegates to repository")
    func appStyleDelegatesToRepository() {
        let expected = AppStyle(wallpaper: WallpaperStyle(location: "bg.mp4"), configDir: "/tmp")
        withDependencies {
            $0.configRepository = MockConfigRepository(style: expected)
        } operation: {
            let useCase = ConfigUseCaseImpl()
            let result = useCase.appStyle
            #expect(result.wallpaper?.location == expected.wallpaper?.location)
            #expect(result.configDir == expected.configDir)
        }
    }

    @Test("appStyle returns exact AppStyle from repository, not default")
    func appStyleReturnsRepositoryValue() {
        let style = AppStyle(wallpaper: WallpaperStyle(location: "custom.mp4"), configDir: "/custom")
        withDependencies {
            $0.configRepository = MockConfigRepository(style: style)
        } operation: {
            let useCase = ConfigUseCaseImpl()
            let result = useCase.appStyle
            let defaultStyle = AppStyle()
            #expect(result.wallpaper?.location != defaultStyle.wallpaper?.location)
            #expect(result.wallpaper?.location == "custom.mp4")
        }
    }
}

// MARK: - Mocks

private struct MockConfigRepository: ConfigRepository {
    let style: AppStyle

    func loadAppStyle() -> AppStyle { style }

    func validate() -> ConfigValidationResult { .defaults }
    func template(format: ConfigFormat) -> String? { nil }
    func writeTemplate(format: ConfigFormat, force: Bool) throws -> String { "" }
}
