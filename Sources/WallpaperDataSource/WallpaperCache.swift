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

    func cachedPath(contentHash: String, ext: String) -> String? {
        let name = "\(contentHash).\(ext)"
        return (try? folder.file(named: name))?.path
    }

    func finalPath(contentHash: String, ext: String) -> String {
        folder.path + "\(contentHash).\(ext)"
    }

    func tempPath(ext: String) -> String {
        folder.path + "tmp_\(UUID().uuidString).\(ext)"
    }

    func contentHash(of filePath: String) throws -> String {
        guard let stream = InputStream(fileAtPath: filePath) else {
            throw CocoaError(.fileNoSuchFile)
        }
        stream.open()
        defer { stream.close() }

        var hasher = SHA256()
        var buffer = [UInt8](repeating: 0, count: 65536)

        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            buffer.prefix(count).withUnsafeBytes { hasher.update(bufferPointer: $0) }
        }

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func resolvedExt(for url: URL, override: String? = nil) -> String {
        override ?? (url.pathExtension.isEmpty ? "mp4" : url.pathExtension)
    }
}
