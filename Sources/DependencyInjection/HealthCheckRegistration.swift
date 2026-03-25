import ConfigRepository
import Dependencies
import Domain
import Foundation
import LyricsDataSource
import MetadataDataSource
import WallpaperDataSource

extension HealthCheckersKey: DependencyKey {
    public static let liveValue: [any HealthCheckable] = {
        @Dependency(\.appStyle) var appStyle

        var checkers: [any HealthCheckable] = [
            ConfigRepositoryImpl(),
            LRCLibAPI.search(query: "test"),
            MusicBrainzAPI.searchRecording(title: "test", artist: nil, duration: nil),
        ]

        if let ai = appStyle.ai {
            checkers.append(OpenAICompatibleAPI(config: ai))
        } else {
            checkers.append(SkippedHealthCheck(serviceName: "AI endpoint", reason: "not configured"))
        }

        // YouTube wallpaper tool checks
        if let wallpaper = appStyle.wallpaper,
            let url = URL(string: wallpaper),
            url.scheme?.lowercased().hasPrefix("http") == true
        {
            checkers.append(contentsOf: WallpaperToolChecker.youtubeCheckers())
        } else {
            checkers.append(SkippedHealthCheck(serviceName: "Wallpaper tools", reason: "no remote wallpaper configured"))
        }

        return checkers
    }()
}

private struct SkippedHealthCheck: HealthCheckable {
    let serviceName: String
    let reason: String

    func healthCheck() async -> HealthCheckResult {
        HealthCheckResult(status: .skip, detail: reason)
    }
}
