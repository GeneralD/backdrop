import Domain
import Foundation
import GRDB

public struct GRDBWallpaperCacheStore: WallpaperCacheStore {
    private let dbManager: DatabaseManager

    public init(dbManager: DatabaseManager) {
        self.dbManager = dbManager
    }

    public func read(url: URL) async -> (contentHash: String, fileExt: String)? {
        try? await dbManager.dbQueue.read { db in
            let record =
                try WallpaperCacheRecord
                .filter(Column("url") == url.absoluteString)
                .fetchOne(db)
            return record.map { ($0.contentHash, $0.fileExt) }
        }
    }

    public func write(url: URL, contentHash: String, fileExt: String) async throws {
        try await dbManager.dbQueue.write { db in
            let record = WallpaperCacheRecord(
                url: url.absoluteString,
                contentHash: contentHash,
                fileExt: fileExt,
                createdAt: julianDayNow()
            )
            try record.save(db, onConflict: .replace)
        }
    }
}

extension GRDBWallpaperCacheStore: Sendable {}

private func julianDayNow() -> Double {
    // Julian Day Number: days since noon Jan 1, 4713 BC
    // Matches SQLite's julianday('now')
    let unixEpochJulianDay = 2_440_587.5
    return unixEpochJulianDay + Date().timeIntervalSince1970 / 86400.0
}
