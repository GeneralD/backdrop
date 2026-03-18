import Dependencies

public protocol AIMetadataCacheRepository: Sendable {
    func read(rawTitle: String, rawArtist: String) async -> SearchCandidate?
    func write(rawTitle: String, rawArtist: String, candidate: SearchCandidate) async throws
}

public enum AIMetadataCacheRepositoryKey: TestDependencyKey {
    public static let testValue: any AIMetadataCacheRepository = NoopAIMetadataCache()
}

extension DependencyValues {
    public var aiMetadataCache: any AIMetadataCacheRepository {
        get { self[AIMetadataCacheRepositoryKey.self] }
        set { self[AIMetadataCacheRepositoryKey.self] = newValue }
    }
}

private struct NoopAIMetadataCache: AIMetadataCacheRepository {
    func read(rawTitle: String, rawArtist: String) async -> SearchCandidate? { nil }
    func write(rawTitle: String, rawArtist: String, candidate: SearchCandidate) async throws {}
}
