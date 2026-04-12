import Foundation

public struct AppLaunchEnvironment: Sendable, Equatable {
    public enum Key: String, CaseIterable, Sendable {
        case uiTestMode = "LYRA_UI_TEST_MODE"
        case lyricsTitle = "LYRA_UI_TEST_TITLE"
        case lyricsArtist = "LYRA_UI_TEST_ARTIST"
        case lyricsLines = "LYRA_UI_TEST_LYRICS"
    }

    public let isUITestMode: Bool
    public let title: String
    public let artist: String
    public let lyricsLines: [String]

    public init(environment: [Key: String]) {
        isUITestMode = Self.parseBoolean(environment[.uiTestMode])
        title = environment[.lyricsTitle] ?? "UI Test Song"
        artist = environment[.lyricsArtist] ?? "UI Test Artist"
        lyricsLines = Self.parseLyrics(environment[.lyricsLines])
    }

    public init(rawEnvironment: [String: String]) {
        self.init(
            environment: Dictionary(
                uniqueKeysWithValues: Key.allCases.compactMap { key in
                    rawEnvironment[key.rawValue].map { (key, $0) }
                }
            )
        )
    }

    public static var current: Self {
        .init(rawEnvironment: ProcessInfo.processInfo.environment)
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
