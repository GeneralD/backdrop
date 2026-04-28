import Domain
import Foundation
@preconcurrency import Papyrus

public struct MusicBrainzMetadataDataSourceImpl {
    private let api: any MusicBrainz

    public init() {
        self.init(api: MusicBrainzAPI(provider: Provider(baseURL: MusicBrainzAPI.baseURL)))
    }

    init(api: any MusicBrainz) {
        self.api = api
    }
}

// Safe: `api` is set at init and never mutated; Papyrus's Provider is configured during construction only.
extension MusicBrainzMetadataDataSourceImpl: @unchecked Sendable {}

extension MusicBrainzMetadataDataSourceImpl: MetadataDataSource {
    public func resolve(track: Track) async -> [MusicBrainzMetadata] {
        let regex = RegexMetadataDataSourceImpl()
        let parsed = regex.parseArtistTitle(track.title)
        let normalized = parsed.title
        let normalizedArtist = regex.normalizeArtist(parsed.artist ?? track.artist)

        for (title, artist) in [(normalized, normalizedArtist), (normalized, nil as String?)] {
            let query = MusicBrainzAPI.luceneQuery(title: title, artist: artist, duration: nil)
            guard let response = try? await api.searchRecording(query: query, fmt: "json", limit: 5) else { continue }
            let candidates = matchRecordings(from: response, regex: regex)
            guard !candidates.isEmpty else { continue }
            return candidates
        }

        return []
    }
}

extension MusicBrainzMetadataDataSourceImpl {
    func matchRecordings(from response: MusicBrainzResponse, regex: RegexMetadataDataSourceImpl) -> [MusicBrainzMetadata] {
        response.recordings.flatMap { recording -> [MusicBrainzMetadata] in
            guard let artistName = recording.artistName else { return [] }
            var seen = Set<String>()
            return [recording.title, regex.normalize(recording.title), regex.stripBrackets(recording.title)]
                .filter { seen.insert($0).inserted }
                .map { title in
                    MusicBrainzMetadata(
                        title: title, artist: artistName,
                        duration: recording.duration, musicbrainzId: recording.id
                    )
                }
        }
    }
}
