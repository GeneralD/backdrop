import Dependencies
import Foundation

public protocol LyricsRepository: Sendable {
    func fetch(
        title: String, artist: String, duration: TimeInterval?,
        onMetadataResolved: @MainActor @Sendable (SearchCandidate) -> Void
    ) async -> LyricsResult?
}

public enum LyricsRepositoryKey: TestDependencyKey {
    public static let testValue: any LyricsRepository = UnimplementedLyricsRepository()
}

extension DependencyValues {
    public var lyricsRepository: any LyricsRepository {
        get { self[LyricsRepositoryKey.self] }
        set { self[LyricsRepositoryKey.self] = newValue }
    }
}

private struct UnimplementedLyricsRepository: LyricsRepository {
    func fetch(title: String, artist: String, duration: TimeInterval?, onMetadataResolved: @MainActor @Sendable (SearchCandidate) -> Void) async -> LyricsResult? {
        nil
    }
}
