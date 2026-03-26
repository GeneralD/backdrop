import Dependencies
import Domain
import Foundation

@MainActor
public final class WallpaperPresenter: ObservableObject {
    @Published public private(set) var wallpaperURL: URL?
    @Published public private(set) var start: TimeInterval?
    @Published public private(set) var end: TimeInterval?
    @Published public private(set) var isLoading: Bool = false

    @Dependency(\.wallpaperInteractor) private var interactor

    public init() {}

    public func resolve() async {
        isLoading = true
        let state = try? await interactor.resolveWallpaper()
        wallpaperURL = state?.url
        start = state?.start
        end = state?.end
        isLoading = false
    }
}
