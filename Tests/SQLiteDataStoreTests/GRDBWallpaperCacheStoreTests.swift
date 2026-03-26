import Foundation
import Testing

@testable import Domain
@testable import SQLiteDataStore

@Suite("GRDBWallpaperCacheStore")
struct GRDBWallpaperCacheStoreTests {
    @Test("read returns nil for unknown URL")
    func readReturnNilForUnknownURL() async throws {
        let db = try DatabaseManager(inMemory: true)
        let store = GRDBWallpaperCacheStore(dbManager: db)
        let url = URL(string: "https://example.com/video.mp4")!
        let result = await store.read(url: url)
        #expect(result == nil)
    }

    @Test("write then read returns stored content hash and ext")
    func writeAndRead() async throws {
        let db = try DatabaseManager(inMemory: true)
        let store = GRDBWallpaperCacheStore(dbManager: db)
        let url = URL(string: "https://example.com/video.mp4")!

        try await store.write(url: url, contentHash: "deadbeef1234", fileExt: "mp4")
        let result = await store.read(url: url)

        #expect(result != nil)
        #expect(result?.contentHash == "deadbeef1234")
        #expect(result?.fileExt == "mp4")
    }

    @Test("different URLs return independent entries")
    func differentURLsAreIndependent() async throws {
        let db = try DatabaseManager(inMemory: true)
        let store = GRDBWallpaperCacheStore(dbManager: db)
        let url1 = URL(string: "https://example.com/a.mp4")!
        let url2 = URL(string: "https://example.com/b.mp4")!

        try await store.write(url: url1, contentHash: "hash_a", fileExt: "mp4")
        try await store.write(url: url2, contentHash: "hash_b", fileExt: "mp4")

        let r1 = await store.read(url: url1)
        let r2 = await store.read(url: url2)
        #expect(r1?.contentHash == "hash_a")
        #expect(r2?.contentHash == "hash_b")
    }

    @Test("two different URLs with same content hash can share the hash")
    func twoURLsWithSameContentHash() async throws {
        let db = try DatabaseManager(inMemory: true)
        let store = GRDBWallpaperCacheStore(dbManager: db)
        let url1 = URL(string: "https://example.com/video.mp4?t=0")!
        let url2 = URL(string: "https://example.com/video.mp4?t=1")!
        let sharedHash = "abc123def456"

        try await store.write(url: url1, contentHash: sharedHash, fileExt: "mp4")
        try await store.write(url: url2, contentHash: sharedHash, fileExt: "mp4")

        let r1 = await store.read(url: url1)
        let r2 = await store.read(url: url2)
        #expect(r1?.contentHash == sharedHash)
        #expect(r2?.contentHash == sharedHash)
    }

    @Test("writing same URL twice overwrites the entry")
    func overwriteExistingEntry() async throws {
        let db = try DatabaseManager(inMemory: true)
        let store = GRDBWallpaperCacheStore(dbManager: db)
        let url = URL(string: "https://example.com/video.mp4")!

        try await store.write(url: url, contentHash: "old_hash", fileExt: "mp4")
        try await store.write(url: url, contentHash: "new_hash", fileExt: "mp4")

        let result = await store.read(url: url)
        #expect(result?.contentHash == "new_hash")
    }
}
