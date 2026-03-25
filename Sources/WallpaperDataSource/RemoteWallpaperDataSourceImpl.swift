import Domain
import Foundation

public struct RemoteWallpaperDataSourceImpl: Sendable {
    public init() {}
}

extension RemoteWallpaperDataSourceImpl: WallpaperDataSource {
    public func resolve(_ location: RemoteWallpaper) async throws -> String {
        let cache = try WallpaperCache()

        if let cached = cache.cachedPath(for: location.url) {
            return cached
        }

        let (tempURL, _) = try await URLSession.shared.download(from: location.url)
        let destPath = cache.destinationPath(for: location.url)
        try FileManager.default.moveItem(at: tempURL, to: URL(fileURLWithPath: destPath))
        return destPath
    }
}
