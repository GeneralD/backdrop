import Foundation

/// Singleton that manages an exclusive `flock` on `~/.cache/lyra/lyra.pid`.
/// The lock lives as long as the process is alive.
public final class ProcessLock: @unchecked Sendable {
    public static let shared = ProcessLock()

    private static let lockDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cache/lyra")
    private static let lockURL = lockDir.appendingPathComponent("lyra.pid")

    private var fileDescriptor: Int32?

    private init() {}

    /// Try to acquire an exclusive lock and write our PID.
    /// Returns `true` on success; subsequent calls return `true` if already acquired.
    public func acquire() -> Bool {
        guard fileDescriptor == nil else { return true }

        try? FileManager.default.createDirectory(at: Self.lockDir, withIntermediateDirectories: true)

        let fd = open(Self.lockURL.path, O_CREAT | O_RDWR, 0o644)
        guard fd >= 0, flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            if fd >= 0 { close(fd) }
            return false
        }

        ftruncate(fd, 0)
        let pidString = "\(ProcessInfo.processInfo.processIdentifier)\n"
        _ = pidString.withCString { Darwin.write(fd, $0, strlen($0)) }

        fileDescriptor = fd
        return true
    }

    /// Check whether another process currently holds the lock.
    public var isLocked: Bool {
        let fd = open(Self.lockURL.path, O_RDONLY)
        guard fd >= 0 else { return false }
        defer { close(fd) }

        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { return true }
        flock(fd, LOCK_UN)
        return false
    }

    /// Remove the PID file. Called after stopping existing processes.
    public func cleanup() {
        try? FileManager.default.removeItem(at: Self.lockURL)
    }
}
