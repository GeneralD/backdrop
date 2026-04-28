import Domain
import Foundation

@testable import MetadataDataSource

/// Manual mock of `MusicBrainz` protocol.
struct MusicBrainzStub: MusicBrainz, @unchecked Sendable {
    let search: @Sendable (_ query: String, _ fmt: String, _ limit: Int) async throws -> MusicBrainzResponse

    init(
        search: @escaping @Sendable (_ query: String, _ fmt: String, _ limit: Int) async throws -> MusicBrainzResponse = { _, _, _ in
            MusicBrainzResponse(recordings: [])
        }
    ) {
        self.search = search
    }

    func searchRecording(query: String, fmt: String, limit: Int) async throws -> MusicBrainzResponse {
        try await search(query, fmt, limit)
    }
}

/// Manual mock of `OpenAICompatible` protocol.
struct OpenAICompatibleStub: OpenAICompatible, @unchecked Sendable {
    let chat: @Sendable (_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse

    init(chat: @escaping @Sendable (_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse) {
        self.chat = chat
    }

    func chatCompletion(request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        try await chat(request)
    }
}
