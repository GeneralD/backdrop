import Domain
import Foundation
import Testing

@testable import MetadataDataSource

@Suite("MusicBrainzHealthCheck")
struct MusicBrainzHealthCheckTests {
    @Test("serviceName is MusicBrainz API")
    func serviceName() {
        #expect(MusicBrainzHealthCheck().serviceName == "MusicBrainz API")
    }

    @Test("healthCheck passes for 2xx responses")
    func healthCheckPasses() async {
        let check = MusicBrainzHealthCheck { request in
            #expect(request.value(forHTTPHeaderField: "User-Agent")?.contains("lyra") == true)
            #expect(request.url?.absoluteString == "https://musicbrainz.org/ws/2/recording?query=test&fmt=json&limit=1")
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (Data(), response)
        }

        let result = await check.healthCheck()

        #expect(result.status == .pass)
        #expect(result.detail.contains("reachable ("))
        #expect(result.latency != nil)
    }

    @Test("healthCheck reports HTTP failures")
    func healthCheckHTTPFailure() async {
        let check = MusicBrainzHealthCheck { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 503, httpVersion: nil, headerFields: nil
            )!
            return (Data(), response)
        }

        let result = await check.healthCheck()

        #expect(result.status == .fail)
        #expect(result.detail == "HTTP 503")
        #expect(result.latency != nil)
    }

    @Test("healthCheck reports non-HTTP response as HTTP -1")
    func healthCheckNonHTTPResponse() async {
        let check = MusicBrainzHealthCheck { request in
            let response = URLResponse(
                url: try #require(request.url),
                mimeType: nil, expectedContentLength: 0, textEncodingName: nil
            )
            return (Data(), response)
        }

        let result = await check.healthCheck()

        #expect(result.status == .fail)
        #expect(result.detail == "HTTP -1")
    }

    @Test("healthCheck reports request errors")
    func healthCheckError() async {
        let check = MusicBrainzHealthCheck { _ in
            throw StubError("stubbed request failure")
        }

        let result = await check.healthCheck()

        #expect(result.status == .fail)
        #expect(result.detail == "stubbed request failure")
        #expect(result.latency == nil)
    }
}
