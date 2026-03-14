import Foundation

/// Bridges to MediaRemote.framework via a persistent swift interpreter subprocess.
/// Compiled binaries cannot access the private framework directly.
/// A small swift script runs as a long-lived daemon, polling every second
/// and writing JSON lines to stdout, which the parent reads via pipe.
public final class MediaRemoteBridge: @unchecked Sendable {
    private let process: Process
    private let reader: FileHandle

    public init() {
        let scriptPath = Self.ensureScript()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", scriptPath]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        self.process = process
        self.reader = pipe.fileHandleForReading
        try? process.run()
    }

    deinit {
        process.terminate()
    }
}

extension MediaRemoteBridge {
    public func poll() async -> MediaRemoteInfo? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async { [reader] in
                guard let line = Self.readLine(from: reader),
                      let data = line.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      json["has_info"] as? Bool == true else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: MediaRemoteInfo(
                    title: json["title"] as? String,
                    artist: json["artist"] as? String,
                    artworkData: (json["artwork_base64"] as? String).flatMap { Data(base64Encoded: $0) },
                    duration: json["duration"] as? TimeInterval,
                    rawElapsed: json["elapsed"] as? TimeInterval,
                    playbackRate: json["rate"] as? Double ?? 1.0,
                    timestamp: (json["timestamp"] as? TimeInterval).map { Date(timeIntervalSinceReferenceDate: $0) }
                ))
            }
        }
    }

    private static func readLine(from handle: FileHandle) -> String? {
        var buffer = Data()
        while true {
            let byte = handle.readData(ofLength: 1)
            guard !byte.isEmpty else { return nil }
            guard byte.first != UInt8(ascii: "\n") else { break }
            buffer.append(byte)
        }
        return String(data: buffer, encoding: .utf8)
    }
}

extension MediaRemoteBridge {
    private static func ensureScript() -> String {
        let cacheDir = URL(fileURLWithPath:
            ProcessInfo.processInfo.environment["XDG_CACHE_HOME"]
                ?? "\(NSHomeDirectory())/.cache"
        ).appendingPathComponent("backdrop")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let path = cacheDir.appendingPathComponent("media-remote-helper.swift").path
        try? script.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    private static let script = """
        import Foundation

        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        guard let handle = dlopen(path, RTLD_NOW),
              let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") else { exit(1) }
        typealias Fn = @convention(c) (DispatchQueue, @escaping (CFDictionary?) -> Void) -> Void
        let fn = unsafeBitCast(sym, to: Fn.self)

        func poll() {
            fn(DispatchQueue.main) { dict in
                guard let d = dict as? [String: Any],
                      d["kMRMediaRemoteNowPlayingInfoTitle"] != nil else {
                    print(#"{"has_info":false}"#)
                    return
                }
                var r: [String: Any] = ["has_info": true]
                r["title"] = d["kMRMediaRemoteNowPlayingInfoTitle"]
                r["artist"] = d["kMRMediaRemoteNowPlayingInfoArtist"]
                r["duration"] = d["kMRMediaRemoteNowPlayingInfoDuration"]
                r["elapsed"] = d["kMRMediaRemoteNowPlayingInfoElapsedTime"]
                r["rate"] = d["kMRMediaRemoteNowPlayingInfoPlaybackRate"]
                if let ts = d["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date {
                    r["timestamp"] = ts.timeIntervalSinceReferenceDate
                }
                if let art = d["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                    r["artwork_base64"] = art.base64EncodedString()
                }
                if let json = try? JSONSerialization.data(withJSONObject: r),
                   let s = String(data: json, encoding: .utf8) {
                    print(s)
                    fflush(stdout)
                }
            }
        }

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in poll() }
        poll()
        RunLoop.main.run()
        """
}
