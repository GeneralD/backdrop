import Dependencies
import Foundation

public protocol WallpaperCacheStore: Sendable {
    func read(url: URL) async -> (contentHash: String, fileExt: String)?
    func write(url: URL, contentHash: String, fileExt: String) async throws
}

public enum WallpaperCacheStoreKey: TestDependencyKey {
    public static let testValue: any WallpaperCacheStore = UnimplementedWallpaperCacheStore()
}

extension DependencyValues {
    public var wallpaperCacheStore: any WallpaperCacheStore {
        get { self[WallpaperCacheStoreKey.self] }
        set { self[WallpaperCacheStoreKey.self] = newValue }
    }
}

private struct UnimplementedWallpaperCacheStore: WallpaperCacheStore {
    func read(url: URL) async -> (contentHash: String, fileExt: String)? { nil }
    func write(url: URL, contentHash: String, fileExt: String) async throws {}
}
