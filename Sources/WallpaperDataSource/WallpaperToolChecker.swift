import Domain

public struct WallpaperToolChecker: HealthCheckable {
    public let serviceName: String
    private let toolName: String
    private let severity: Severity

    enum Severity { case required, optional }

    private init(serviceName: String, toolName: String, severity: Severity) {
        self.serviceName = serviceName
        self.toolName = toolName
        self.severity = severity
    }

    public func healthCheck() async -> HealthCheckResult {
        guard let path = ExecutableFinder.find(toolName) else {
            switch severity {
            case .required:
                return HealthCheckResult(status: .fail, detail: "not found — install with: brew install \(toolName)")
            case .optional:
                return HealthCheckResult(status: .pass, detail: "not found (optional — YouTube wallpaper may not loop)")
            }
        }
        return HealthCheckResult(status: .pass, detail: path)
    }
}

extension WallpaperToolChecker {
    public static let ytdlp = WallpaperToolChecker(
        serviceName: "yt-dlp",
        toolName: "yt-dlp",
        severity: .required
    )

    public static let uvx = WallpaperToolChecker(
        serviceName: "uvx (yt-dlp)",
        toolName: "uvx",
        severity: .required
    )

    public static let ffmpeg = WallpaperToolChecker(
        serviceName: "ffmpeg",
        toolName: "ffmpeg",
        severity: .optional
    )

    /// Returns checkers for YouTube wallpaper tools.
    /// yt-dlp is checked first; if not found, uvx is checked as alternative.
    public static func youtubeCheckers() -> [WallpaperToolChecker] {
        let hasYtdlp = ExecutableFinder.find("yt-dlp") != nil
        let downloadChecker: WallpaperToolChecker = hasYtdlp ? .ytdlp : .uvx
        return [downloadChecker, .ffmpeg]
    }
}
