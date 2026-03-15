import Alamofire
import BackdropDomain
import CollectionKit
import Dependencies
import Foundation

public struct LyricsSearchService: LyricsRepository {
    @Dependency(\.metadataCache) private var metadataCache

    public init() {}
}

extension LyricsSearchService {
    public func fetch(title: String, artist: String, duration: TimeInterval?) async -> LyricsResult? {
        // Stage 1: Try MusicBrainz (cached or remote) for accurate metadata → LRCLIB get
        if let result = await fetchViaMusicBrainz(title: title, artist: artist, duration: duration) {
            return result
        }

        // Stage 2: Fallback to candidate-based search
        let candidates = TitleParser().generateCandidates(title: title, artist: artist)

        let getResults = await candidates
            .unless(\.artist.isEmpty)
            .asyncCompactMap { c in await lrclib(LyricsResult.self, from: .get(title: c.title, artist: c.artist, duration: duration)) }
            .filter { $0.plainLyrics != nil || $0.syncedLyrics != nil }

        if let synced = getResults.first(where: { $0.syncedLyrics != nil }) { return synced }
        if let first = getResults.first { return first }
        return await searchFallback(candidates: candidates)
    }
}

// MARK: - MusicBrainz → LRCLIB pipeline

private extension LyricsSearchService {
    func fetchViaMusicBrainz(title: String, artist: String, duration: TimeInterval?) async -> LyricsResult? {
        let normalized = TitleParser().stripBrackets(title)

        // Check cache first
        if let cached = await metadataCache.read(title: normalized, artist: artist) {
            let result = await lrclib(LyricsResult.self, from: .get(
                title: cached.title, artist: cached.artist, duration: cached.duration
            ))
            if let result, result.plainLyrics != nil || result.syncedLyrics != nil {
                return result
            }
        }

        // Query MusicBrainz
        guard let response: MusicBrainzResponse = await musicbrainz(.searchRecording(
            title: normalized, artist: artist, duration: duration
        )) else { return nil }

        for recording in response.recordings {
            guard let artistName = recording.artistName else { continue }
            let result = await lrclib(LyricsResult.self, from: .get(
                title: recording.title, artist: artistName, duration: recording.duration
            ))
            guard let result, result.plainLyrics != nil || result.syncedLyrics != nil else { continue }

            // Cache the successful match
            let metadata = ResolvedMetadata(
                title: recording.title, artist: artistName,
                duration: recording.duration, musicbrainzId: recording.id
            )
            try? await metadataCache.write(queryTitle: normalized, queryArtist: artist, metadata: metadata)
            return result
        }
        return nil
    }
}

// MARK: - Fallback search

private extension LyricsSearchService {
    func searchFallback(candidates: [SearchCandidate]) async -> LyricsResult? {
        let matches = await candidates
            .map { $0.artist.isEmpty ? $0.title : "\($0.title) \($0.artist)" }
            .asyncCompactMap { await lrclib([LyricsResult].self, from: .search(query: $0)) }
            .compactMap { response in
                response.first { $0.syncedLyrics != nil } ?? response.first { $0.plainLyrics != nil }
            }
        return matches.first { $0.syncedLyrics != nil }
            ?? matches.first
    }
}

// MARK: - API requests

private extension LyricsSearchService {
    func lrclib<T: Decodable & Sendable>(_ type: T.Type, from api: LRCLibAPI) async -> T? {
        await AF.request(api)
            .validate(statusCode: 200 ..< 300)
            .serializingDecodable(type)
            .response.value
    }

    func musicbrainz<T: Decodable & Sendable>(_ api: MusicBrainzAPI) async -> T? {
        await AF.request(api)
            .validate(statusCode: 200 ..< 300)
            .serializingDecodable(T.self)
            .response.value
    }
}

// MARK: - DependencyKey

extension LyricsRepositoryKey: DependencyKey {
    public static let liveValue: any LyricsRepository = LyricsSearchService()
}

extension LyricsSearchService: Sendable {}

// MARK: - Async helpers

private extension Array {
    func asyncCompactMap<T>(_ transform: (Element) async -> T?) async -> [T] {
        var results: [T] = []
        for element in self {
            guard let value = await transform(element) else { continue }
            results.append(value)
        }
        return results
    }
}
