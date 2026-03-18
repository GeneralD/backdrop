import Dependencies

public protocol AITitleExtractor: Sendable {
    func extract(rawTitle: String, rawArtist: String) async -> SearchCandidate?
}

public enum AITitleExtractorKey: TestDependencyKey {
    public static let testValue: any AITitleExtractor = NoopAITitleExtractor()
}

extension DependencyValues {
    public var aiTitleExtractor: any AITitleExtractor {
        get { self[AITitleExtractorKey.self] }
        set { self[AITitleExtractorKey.self] = newValue }
    }
}

private struct NoopAITitleExtractor: AITitleExtractor {
    func extract(rawTitle: String, rawArtist: String) async -> SearchCandidate? { nil }
}
