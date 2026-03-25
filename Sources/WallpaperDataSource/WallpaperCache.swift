import CryptoKit
import Files
import Foundation

struct WallpaperCache {
    let folder: Folder

    init() throws {
        let cachePath =
            ProcessInfo.processInfo.environment["XDG_CACHE_HOME"]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : $0 }
            ?? "\(Folder.home.path).cache"
        let wallpaperPath = "\(cachePath)/lyra/wallpapers"
        try FileManager.default.createDirectory(atPath: wallpaperPath, withIntermediateDirectories: true)
        folder = try Folder(path: wallpaperPath)
    }

    func cachedPath(for url: URL, ext: String? = nil) -> String? {
        let name = fileName(for: url, ext: ext)
        return (try? folder.file(named: name))?.path
    }

    func destinationPath(for url: URL, ext: String? = nil) -> String {
        folder.path + fileName(for: url, ext: ext)
    }

    private func fileName(for url: URL, ext: String?) -> String {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hex = hash.map { String(format: "%02x", $0) }.joined()
        let resolvedExt = ext ?? (url.pathExtension.isEmpty ? "mp4" : url.pathExtension)
        return "\(hex).\(resolvedExt)"
    }
}
