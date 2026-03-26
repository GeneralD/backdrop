import Foundation
import Testing

@testable import WallpaperDataSource

@Suite("WallpaperCache", .serialized)
struct WallpaperCacheTests {
    private func withTempCacheDir<T>(_ body: (String) throws -> T) throws -> T {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        setenv("XDG_CACHE_HOME", tmp, 1)
        defer {
            unsetenv("XDG_CACHE_HOME")
            try? FileManager.default.removeItem(atPath: tmp)
        }
        return try body(tmp)
    }

    // MARK: - Content-hash-based caching

    @Test("cachedPath returns nil when file does not exist")
    func cachedPathReturnsNilWhenMissing() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            #expect(cache.cachedPath(contentHash: "abc123", ext: "mp4") == nil)
        }
    }

    @Test("cachedPath returns path when file exists")
    func cachedPathReturnsPathWhenExists() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let path = cache.finalPath(contentHash: "abc123", ext: "mp4")
            FileManager.default.createFile(atPath: path, contents: Data())
            let cached = cache.cachedPath(contentHash: "abc123", ext: "mp4")
            #expect(cached != nil)
            #expect(cached == path)
        }
    }

    @Test("finalPath uses content hash and ext")
    func finalPathUsesContentHashAndExt() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let path = cache.finalPath(contentHash: "deadbeef", ext: "mp4")
            #expect(path.hasSuffix("deadbeef.mp4"))
        }
    }

    @Test("tempPath uses uuid and ext, differs between calls")
    func tempPathIsUniquePerCall() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let p1 = cache.tempPath(ext: "mp4")
            let p2 = cache.tempPath(ext: "mp4")
            #expect(p1 != p2)
            #expect(p1.hasSuffix(".mp4"))
            #expect(p2.hasSuffix(".mp4"))
        }
    }

    // MARK: - contentHash

    @Test("contentHash produces consistent 64-hex SHA256 for file contents")
    func contentHashIsConsistent() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let tmpFile = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".bin").path
            defer { try? FileManager.default.removeItem(atPath: tmpFile) }
            let data = Data(repeating: 0xAB, count: 1024)
            try data.write(to: URL(fileURLWithPath: tmpFile))

            let hash1 = try cache.contentHash(of: tmpFile)
            let hash2 = try cache.contentHash(of: tmpFile)
            #expect(hash1 == hash2)
            #expect(hash1.count == 64)
            #expect(hash1.allSatisfy { $0.isHexDigit })
        }
    }

    @Test("contentHash differs for different file contents")
    func contentHashDiffersForDifferentContents() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let tmpA = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".bin").path
            let tmpB = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".bin").path
            defer {
                try? FileManager.default.removeItem(atPath: tmpA)
                try? FileManager.default.removeItem(atPath: tmpB)
            }
            try Data(repeating: 0xAA, count: 512).write(to: URL(fileURLWithPath: tmpA))
            try Data(repeating: 0xBB, count: 512).write(to: URL(fileURLWithPath: tmpB))

            let hashA = try cache.contentHash(of: tmpA)
            let hashB = try cache.contentHash(of: tmpB)
            #expect(hashA != hashB)
        }
    }

    @Test("contentHash throws for missing file")
    func contentHashThrowsForMissingFile() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            #expect(throws: (any Error).self) {
                try cache.contentHash(of: "/nonexistent/path/file.mp4")
            }
        }
    }

    // MARK: - resolvedExt

    @Test("resolvedExt uses override when provided")
    func resolvedExtUsesOverride() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url = URL(string: "https://example.com/video.mov")!
            #expect(cache.resolvedExt(for: url, override: "webm") == "webm")
        }
    }

    @Test("resolvedExt uses URL path extension when no override")
    func resolvedExtUsesURLExtension() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url = URL(string: "https://example.com/video.mov")!
            #expect(cache.resolvedExt(for: url) == "mov")
        }
    }

    @Test("resolvedExt defaults to mp4 when URL has no extension")
    func resolvedExtDefaultsMp4() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url = URL(string: "https://example.com/noext")!
            #expect(cache.resolvedExt(for: url) == "mp4")
        }
    }
}
