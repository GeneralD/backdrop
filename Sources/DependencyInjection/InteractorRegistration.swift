import Dependencies
import Domain
import TrackInteractor
import WallpaperInteractor

extension TrackInteractorKey: DependencyKey {
    public static let liveValue: any TrackInteractor = TrackInteractorImpl()
}

extension WallpaperInteractorKey: DependencyKey {
    public static let liveValue: any WallpaperInteractor = WallpaperInteractorImpl()
}
