import Dependencies
import Domain
import Foundation

public struct RemoteWallpaperDataSourceImpl: Sendable {
    @Dependency(\.wallpaperCacheStore) private var cacheStore

    public init() {}
}

extension RemoteWallpaperDataSourceImpl: WallpaperDataSource {
    public func resolve(_ location: RemoteWallpaper) async throws -> String {
        let cache = try WallpaperCache()
        let ext = cache.resolvedExt(for: location.url)

        if let entry = await cacheStore.read(url: location.url),
            let path = cache.cachedPath(contentHash: entry.contentHash, ext: entry.fileExt)
        {
            return path
        }

        let (tempURL, response) = try await URLSession.shared.download(from: location.url)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            try? FileManager.default.removeItem(at: tempURL)
            throw URLError(.badServerResponse)
        }

        let tempPath = cache.tempPath(ext: ext)
        let tempFileURL = URL(fileURLWithPath: tempPath)
        try? FileManager.default.removeItem(at: tempFileURL)
        try FileManager.default.moveItem(at: tempURL, to: tempFileURL)

        let hash = try cache.contentHash(of: tempPath)
        let finalPath = cache.finalPath(contentHash: hash, ext: ext)

        if !FileManager.default.fileExists(atPath: finalPath) {
            try FileManager.default.moveItem(
                at: tempFileURL, to: URL(fileURLWithPath: finalPath))
        } else {
            try? FileManager.default.removeItem(at: tempFileURL)
        }

        try await cacheStore.write(url: location.url, contentHash: hash, fileExt: ext)
        return finalPath
    }
}
