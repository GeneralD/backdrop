import Foundation

public struct AppLaunchEnvironment: Sendable, Equatable {
    private static let uiTestModeKey = "LYRA_UI_TEST_MODE"
    private static let lyricsTitleKey = "LYRA_UI_TEST_TITLE"
    private static let lyricsArtistKey = "LYRA_UI_TEST_ARTIST"
    private static let lyricsLinesKey = "LYRA_UI_TEST_LYRICS"

    public let isUITestMode: Bool
    public let title: String
    public let artist: String
    public let lyricsLines: [String]

    public init(environment: [String: String]) {
        isUITestMode = Self.parseBoolean(environment[Self.uiTestModeKey])
        title = environment[Self.lyricsTitleKey] ?? "UI Test Song"
        artist = environment[Self.lyricsArtistKey] ?? "UI Test Artist"
        lyricsLines = Self.parseLyrics(environment[Self.lyricsLinesKey])
    }

    public static var current: Self {
        .init(environment: ProcessInfo.processInfo.environment)
    }

    private static func parseBoolean(_ value: String?) -> Bool {
        switch value?.lowercased() {
        case "1", "true", "yes", "on": true
        default: false
        }
    }

    private static func parseLyrics(_ value: String?) -> [String] {
        let defaultLines = ["First UI test lyric", "Second UI test lyric"]
        guard let value else { return defaultLines }

        let lines =
            value
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.isEmpty ? defaultLines : lines
    }
}
