import Dependencies
import Domain
import Foundation

public struct WallpaperRepositoryImpl: Sendable {
    @Dependency(\.localWallpaperDataSource) private var local
    @Dependency(\.remoteWallpaperDataSource) private var remote
    @Dependency(\.youtubeWallpaperDataSource) private var youtube

    public init() {}
}

extension WallpaperRepositoryImpl: WallpaperRepository {
    public func resolve(value: String?, configDir: String) async throws -> URL? {
        guard let value, !value.isEmpty else { return nil }
        let path = try await resolveToPath(value: value, configDir: configDir)
        return URL(fileURLWithPath: path)
    }
}

extension WallpaperRepositoryImpl {
    private func resolveToPath(value: String, configDir: String) async throws -> String {
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            return try await local.resolve(LocalWallpaper(path: value, configDir: configDir))
        }

        guard !url.isYouTube else {
            return try await youtube.resolve(YouTubeWallpaper(url: url))
        }

        return try await remote.resolve(RemoteWallpaper(url: url))
    }
}
