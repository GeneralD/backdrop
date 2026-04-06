@preconcurrency import Combine
import Dependencies
import Domain
import Foundation
import Testing

@testable import TrackInteractor

// MARK: - Stubs

/// PlaybackUseCase that emits controlled NowPlaying values.
private final class StubPlaybackUseCase: PlaybackUseCase, @unchecked Sendable {
    let subject = PassthroughSubject<NowPlaying?, Never>()

    func fetchNowPlaying() async -> NowPlaying? { nil }

    func observeNowPlaying() -> AsyncStream<NowPlaying?> {
        AsyncStream { continuation in
            let cancellable = subject.sink(
                receiveCompletion: { _ in continuation.finish() },
                receiveValue: { continuation.yield($0) }
            )
            continuation.onTermination = { _ in cancellable.cancel() }
        }
    }

    func elapsedTime(for np: NowPlaying) -> TimeInterval? { np.rawElapsed }
}

/// MetadataUseCase with configurable delay to simulate slow resolution.
private struct DelayedMetadataUseCase: MetadataUseCase, Sendable {
    let delay: Duration

    func resolve(track: Track) async -> Track? { nil }
    func resolveCandidates(track: Track) async -> [Track] {
        try? await Task.sleep(for: delay)
        return [track]
    }
}

/// Instant MetadataUseCase — no delay.
private struct InstantMetadataUseCase: MetadataUseCase, Sendable {
    func resolve(track: Track) async -> Track? { nil }
    func resolveCandidates(track: Track) async -> [Track] { [] }
}

/// LyricsUseCase that returns identifiable lyrics per track.
private struct StubLyricsUseCase: LyricsUseCase, Sendable {
    func fetchLyrics(track: Track) async -> LyricsResult {
        LyricsResult(trackName: track.title, artistName: track.artist, syncedLyrics: "[\(track.title)]")
    }

    func fetchLyrics(candidates: [Track]) async -> LyricsResult {
        guard let first = candidates.first else { return LyricsResult() }
        return await fetchLyrics(track: first)
    }

    func parseLyricsContent(from result: LyricsResult?) -> LyricsContent? {
        guard let synced = result?.syncedLyrics, !synced.isEmpty else { return nil }
        return .timed([LyricLine(time: 0, text: synced)])
    }
}

/// ConfigUseCase stub.
private struct StubConfigUseCase: ConfigUseCase, Sendable {
    var appStyle: AppStyle { .init() }
    func template(format: ConfigFormat) -> String? { nil }
    func writeTemplate(format: ConfigFormat, force: Bool) throws -> String { "" }
    var existingConfigPath: String? { nil }
}

// MARK: - Helpers

/// Thread-safe collector for TrackUpdate values.
private final class UpdateCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var _updates: [TrackUpdate] = []

    var updates: [TrackUpdate] {
        lock.withLock { _updates }
    }

    func append(_ update: TrackUpdate) {
        lock.withLock { _updates.append(update) }
    }

    func contains(where predicate: (TrackUpdate) -> Bool) -> Bool {
        lock.withLock { _updates.contains(where: predicate) }
    }
}

/// Poll until condition is met or timeout.
private func waitUntil(
    timeout: Duration = .seconds(5),
    condition: @Sendable () -> Bool
) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        guard ContinuousClock.now < deadline else {
            struct Timeout: Error {}
            throw Timeout()
        }
        try await Task.sleep(for: .milliseconds(50))
    }
}

// MARK: - Tests

@Suite("TrackInteractor race condition", .serialized)
struct TrackInteractorRaceTests {

    @Test("rapid track change cancels stale resolution — only latest track emits resolved")
    func rapidTrackChangeCancelsStale() async throws {
        let playback = StubPlaybackUseCase()

        let interactor = withDependencies {
            $0.playbackUseCase = playback
            $0.metadataUseCase = DelayedMetadataUseCase(delay: .milliseconds(500))
            $0.lyricsUseCase = StubLyricsUseCase()
            $0.configUseCase = StubConfigUseCase()
        } operation: {
            TrackInteractorImpl()
        }

        let collector = UpdateCollector()
        let cancellable = interactor.trackChange
            .sink { collector.append($0) }

        // Send track A
        playback.subject.send(
            NowPlaying(title: "Track A", artist: "Artist A", artworkData: nil, duration: nil, rawElapsed: nil, playbackRate: 1, timestamp: nil))

        // Wait just enough for loading to emit but not for resolution to complete
        try await Task.sleep(for: .milliseconds(100))

        // Send track B before A resolves (A's metadata takes 500ms)
        playback.subject.send(
            NowPlaying(title: "Track B", artist: "Artist B", artworkData: nil, duration: nil, rawElapsed: nil, playbackRate: 1, timestamp: nil))

        // Poll until Track B resolves
        try await waitUntil {
            collector.updates.contains { $0.title == "Track B" && ($0.lyricsState == .resolved || $0.lyricsState == .notFound) }
        }

        cancellable.cancel()

        // Filter to only resolved updates (not loading)
        let resolved = collector.updates.filter { $0.lyricsState == .resolved || $0.lyricsState == .notFound }

        // Track A's resolved should NOT be present (cancelled by switchToLatest)
        let hasTrackA = resolved.contains { $0.title == "Track A" }
        let hasTrackB = resolved.contains { $0.title == "Track B" }

        #expect(!hasTrackA, "Track A resolution should be cancelled")
        #expect(hasTrackB, "Track B resolution should complete")
    }

    @Test("nil NowPlaying does not emit TrackUpdate — last track info is retained")
    func nilNowPlayingKeepsLastTrack() async throws {
        let playback = StubPlaybackUseCase()

        let interactor = withDependencies {
            $0.playbackUseCase = playback
            $0.metadataUseCase = InstantMetadataUseCase()
            $0.lyricsUseCase = StubLyricsUseCase()
            $0.configUseCase = StubConfigUseCase()
        } operation: {
            TrackInteractorImpl()
        }

        let collector = UpdateCollector()
        let cancellable = interactor.trackChange
            .sink { collector.append($0) }

        // Send a track
        playback.subject.send(
            NowPlaying(
                title: "Track A", artist: "Artist A", artworkData: nil,
                duration: nil, rawElapsed: nil, playbackRate: 1, timestamp: nil))

        // Wait for Track A to resolve (Combine pipeline + withDependencies scope limitation
        // prevents polling — async resolution runs outside the dependency scope)
        try await Task.sleep(for: .seconds(2))

        let countBeforeNil = collector.updates.count

        // Send nil (playback stopped)
        playback.subject.send(nil)

        // Wait to confirm no new emission
        try await Task.sleep(for: .milliseconds(500))

        cancellable.cancel()

        // nil NowPlaying must NOT produce any TrackUpdate
        let afterNil = collector.updates.dropFirst(countBeforeNil)
        #expect(afterNil.isEmpty, "nil NowPlaying should not emit any TrackUpdate — last track stays visible")
    }

    @Test("track A loading emits but resolved does not when B arrives quickly")
    func staleLoadingVisibleButResolvedCancelled() async throws {
        let playback = StubPlaybackUseCase()

        let interactor = withDependencies {
            $0.playbackUseCase = playback
            $0.metadataUseCase = DelayedMetadataUseCase(delay: .milliseconds(500))
            $0.lyricsUseCase = StubLyricsUseCase()
            $0.configUseCase = StubConfigUseCase()
        } operation: {
            TrackInteractorImpl()
        }

        let collector = UpdateCollector()
        let cancellable = interactor.trackChange
            .sink { collector.append($0) }

        playback.subject.send(
            NowPlaying(title: "Track A", artist: "Artist A", artworkData: nil, duration: nil, rawElapsed: nil, playbackRate: 1, timestamp: nil))

        try await Task.sleep(for: .milliseconds(100))

        playback.subject.send(
            NowPlaying(title: "Track B", artist: "Artist B", artworkData: nil, duration: nil, rawElapsed: nil, playbackRate: 1, timestamp: nil))

        // Poll until Track B resolves
        try await waitUntil {
            collector.updates.contains { $0.title == "Track B" && ($0.lyricsState == .resolved || $0.lyricsState == .notFound) }
        }

        cancellable.cancel()

        // Resolved for Track A must NOT appear
        let resolvedA = collector.updates.filter { $0.title == "Track A" && ($0.lyricsState == .resolved || $0.lyricsState == .notFound) }

        #expect(resolvedA.isEmpty, "Track A resolution must be cancelled by switchToLatest")
    }

    // MARK: - Volume mute deduplication

    @Test("dedup logic: same title with empty artist on either side is treated as same track")
    func dedupLogicVolumeMute() {
        let isDuplicate: (NowPlaying, NowPlaying) -> Bool = { prev, cur in
            let prevArtist = prev.artist ?? ""
            let curArtist = cur.artist ?? ""
            guard !prevArtist.isEmpty, !curArtist.isEmpty else {
                return prev.title == cur.title
            }
            return prev.title == cur.title && prevArtist == curArtist
        }

        let normal = NowPlaying(
            title: "Song", artist: "Artist", artworkData: nil,
            duration: nil, rawElapsed: nil, playbackRate: 1, timestamp: nil)
        let muted = NowPlaying(
            title: "Song", artist: "", artworkData: nil,
            duration: nil, rawElapsed: nil, playbackRate: 1, timestamp: nil)
        let nilArtist = NowPlaying(
            title: "Song", artist: nil, artworkData: nil,
            duration: nil, rawElapsed: nil, playbackRate: 1, timestamp: nil)
        let differentTrack = NowPlaying(
            title: "Other Song", artist: "Artist", artworkData: nil,
            duration: nil, rawElapsed: nil, playbackRate: 1, timestamp: nil)
        let sameTitleDiffArtist = NowPlaying(
            title: "Song", artist: "Other Artist", artworkData: nil,
            duration: nil, rawElapsed: nil, playbackRate: 1, timestamp: nil)

        #expect(isDuplicate(normal, muted), "Muted (empty artist) should match normal")
        #expect(isDuplicate(muted, normal), "Restored should match muted")
        #expect(isDuplicate(normal, nilArtist), "Nil artist should match normal")
        #expect(!isDuplicate(normal, differentTrack), "Different title should not match")
        #expect(!isDuplicate(normal, sameTitleDiffArtist), "Different non-empty artist should not match")
        #expect(isDuplicate(muted, muted), "Both empty artist, same title should match")
    }
}
