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

    // MARK: - Normal Behavior

    @Test("same URL produces same file name via cachedPath and destinationPath")
    func sameURLProducesSameFileName() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url = URL(string: "https://example.com/video.mp4")!
            let destination = cache.destinationPath(for: url)
            // File does not exist yet, so cachedPath returns nil — but destination should be consistent
            let destination2 = cache.destinationPath(for: url)
            #expect(destination == destination2)

            // Create the file so cachedPath returns a value
            FileManager.default.createFile(atPath: destination, contents: Data())
            let cached = cache.cachedPath(for: url)
            #expect(cached == destination)
        }
    }

    @Test("different URLs produce different file names")
    func differentURLsProduceDifferentFileNames() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url1 = URL(string: "https://example.com/a.mp4")!
            let url2 = URL(string: "https://example.com/b.mp4")!
            #expect(cache.destinationPath(for: url1) != cache.destinationPath(for: url2))
        }
    }

    @Test("default extension is mp4 when URL has no extension")
    func defaultExtensionIsMp4() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url = URL(string: "https://example.com/noext")!
            let path = cache.destinationPath(for: url)
            #expect(path.hasSuffix(".mp4"))
        }
    }

    @Test("preserves URL path extension when present")
    func preservesURLPathExtension() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url = URL(string: "https://example.com/video.mov")!
            let path = cache.destinationPath(for: url)
            #expect(path.hasSuffix(".mov"))
        }
    }

    // MARK: - Boundary Conditions

    @Test("URL with query parameters: different query produces different hash")
    func queryParametersAffectHash() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url1 = URL(string: "https://example.com/video.mp4?token=abc")!
            let url2 = URL(string: "https://example.com/video.mp4?token=xyz")!
            #expect(cache.destinationPath(for: url1) != cache.destinationPath(for: url2))
        }
    }

    @Test("custom ext parameter overrides URL extension")
    func customExtOverridesURLExtension() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url = URL(string: "https://example.com/video.mov")!
            let path = cache.destinationPath(for: url, ext: "webm")
            #expect(path.hasSuffix(".webm"))
        }
    }

    @Test("cachedPath returns nil when file does not exist")
    func cachedPathReturnsNilWhenMissing() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url = URL(string: "https://example.com/nonexistent.mp4")!
            #expect(cache.cachedPath(for: url) == nil)
        }
    }

    @Test("cachedPath returns path when file exists")
    func cachedPathReturnsPathWhenExists() throws {
        try withTempCacheDir { _ in
            let cache = try WallpaperCache()
            let url = URL(string: "https://example.com/exists.mp4")!
            let dest = cache.destinationPath(for: url)
            FileManager.default.createFile(atPath: dest, contents: Data())
            let cached = cache.cachedPath(for: url)
            #expect(cached != nil)
            #expect(cached == dest)
        }
    }

    // MARK: - Properties

    @Test("file name matches pattern: 64 hex chars + dot + extension")
    func fileNameMatchesHexPattern() throws {
        try withTempCacheDir { tmp in
            let cache = try WallpaperCache()
            let urls = [
                URL(string: "https://example.com/a.mp4")!,
                URL(string: "https://example.com/b")!,
                URL(string: "https://example.com/c.mov")!,
            ]
            let hexPattern = #/^[0-9a-f]{64}\.\w+$/#
            urls.forEach { url in
                let path = cache.destinationPath(for: url)
                let fileName = URL(fileURLWithPath: path).lastPathComponent
                #expect(fileName.wholeMatch(of: hexPattern) != nil, "Expected hex pattern, got: \(fileName)")
            }
        }
    }

    @Test("SHA256 is deterministic: same URL always produces same hash")
    func sha256IsDeterministic() throws {
        try withTempCacheDir { _ in
            let cache1 = try WallpaperCache()
            let cache2 = try WallpaperCache()
            let url = URL(string: "https://example.com/deterministic.mp4")!
            #expect(cache1.destinationPath(for: url) == cache2.destinationPath(for: url))
        }
    }
}
