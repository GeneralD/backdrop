import Domain
import Foundation
@preconcurrency import Papyrus
import Testing

@testable import LyricsDataSource

/// URL-construction tests: verify that `LRCLibAPI` (Papyrus-generated)
/// produces the expected `URLRequest` for each endpoint by injecting a
/// custom `HTTPService` that records the outgoing request.
@Suite("LRCLibAPI URL construction")
struct LRCLibAPIURLConstructionTests {
    private func makeAPI(_ recorder: TestHTTPService) -> any LRCLib {
        LRCLibAPI(provider: Provider(baseURL: "https://lrclib.net", http: recorder))
    }

    @Test("get builds correct URL with title, artist, and duration")
    func getEndpointConstruction() async {
        let recorder = TestHTTPService()
        let api = makeAPI(recorder)

        _ = try? await api.get(trackName: "Numb", artistName: "Linkin Park", duration: 187)
        let url = recorder.captured?.url?.absoluteString ?? ""

        #expect(url.contains("lrclib.net/api/get"))
        #expect(url.contains("track_name=Numb"))
        #expect(url.contains("artist_name=Linkin%20Park"))
        #expect(url.contains("duration=187"))
    }

    @Test("get omits duration when nil")
    func getEndpointWithoutDuration() async {
        let recorder = TestHTTPService()
        let api = makeAPI(recorder)

        _ = try? await api.get(trackName: "Song", artistName: "Artist", duration: nil)
        let url = recorder.captured?.url?.absoluteString ?? ""

        #expect(!url.contains("duration"))
    }

    @Test("search builds correct URL with query")
    func searchEndpointConstruction() async {
        let recorder = TestHTTPService()
        let api = makeAPI(recorder)

        _ = try? await api.search(q: "hello world")
        let url = recorder.captured?.url?.absoluteString ?? ""

        #expect(url.contains("lrclib.net/api/search"))
        #expect(url.contains("q=hello%20world"))
    }

    @Test("requests carry the User-Agent header")
    func userAgentHeader() async {
        let recorder = TestHTTPService()
        let api = makeAPI(recorder)

        _ = try? await api.get(trackName: "T", artistName: "A", duration: nil)

        #expect(recorder.captured?.value(forHTTPHeaderField: "User-Agent") == "lyra (https://github.com/GeneralD/lyra)")
    }

    @Test("get and search use HTTP GET")
    func httpMethod() async {
        let recorder = TestHTTPService()
        let api = makeAPI(recorder)

        _ = try? await api.search(q: "test")
        #expect(recorder.captured?.httpMethod == "GET")

        _ = try? await api.get(trackName: "x", artistName: "y", duration: nil)
        #expect(recorder.captured?.httpMethod == "GET")
    }

    @Test("special characters in query are percent-encoded")
    func specialCharactersEncoded() async {
        let recorder = TestHTTPService()
        let api = makeAPI(recorder)

        _ = try? await api.search(q: "AC/DC & Friends")
        let url = recorder.captured?.url?.absoluteString ?? ""

        // `&` and `/` must be encoded inside the query value
        #expect(url.contains("q=AC%2FDC%20%26%20Friends"))
    }

    @Test("zero duration is sent (not omitted)")
    func zeroDurationSent() async {
        let recorder = TestHTTPService()
        let api = makeAPI(recorder)

        _ = try? await api.get(trackName: "x", artistName: "y", duration: 0)
        let url = recorder.captured?.url?.absoluteString ?? ""

        #expect(url.contains("duration=0"))
    }
}
