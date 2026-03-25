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

        let (tempURL, response) = try await URLSession.shared.download(from: location.url)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            try? FileManager.default.removeItem(at: tempURL)
            throw URLError(.badServerResponse)
        }

        let destPath = cache.destinationPath(for: location.url)
        try FileManager.default.moveItem(at: tempURL, to: URL(fileURLWithPath: destPath))
        return destPath
    }
}
