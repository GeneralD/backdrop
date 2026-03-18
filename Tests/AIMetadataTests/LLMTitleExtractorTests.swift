import Dependencies
import Domain
import Testing

@testable import AIMetadata

@Suite("LLMTitleExtractor")
struct LLMTitleExtractorTests {
    @Test("Returns nil when AI is not configured")
    func unconfiguredReturnsNil() async {
        let extractor = withDependencies {
            $0.config = ResolvedConfig(ai: nil)
        } operation: {
            LLMTitleExtractor()
        }

        let result = await extractor.extract(rawTitle: "Some Song", rawArtist: "Some Artist")
        #expect(result == nil)
    }

    @Test("Returns cached result without API call")
    func cacheHitSkipsAPI() async {
        let expected = SearchCandidate(title: "Cached Title", artist: "Cached Artist")
        let extractor = withDependencies {
            $0.config = ResolvedConfig(ai: ResolvedAIConfig(
                endpoint: "https://example.com/v1",
                model: "test-model",
                apiKey: "test-key"
            ))
            $0.aiMetadataCache = StubAIMetadataCache(stubbedResult: expected)
        } operation: {
            LLMTitleExtractor()
        }

        let result = await extractor.extract(rawTitle: "raw title", rawArtist: "raw artist")
        #expect(result == expected)
    }
}

private struct StubAIMetadataCache: AIMetadataCacheRepository {
    let stubbedResult: SearchCandidate?

    func read(rawTitle: String, rawArtist: String) async -> SearchCandidate? { stubbedResult }
    func write(rawTitle: String, rawArtist: String, candidate: SearchCandidate) async throws {}
}
