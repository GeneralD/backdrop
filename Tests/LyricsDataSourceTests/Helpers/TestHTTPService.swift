import Foundation
@preconcurrency import Papyrus
import os

final class TestHTTPService: HTTPService, @unchecked Sendable {
    private let storage = OSAllocatedUnfairLock<URLRequest?>(initialState: nil)
    private let stub: @Sendable (URLRequest) -> (status: Int, body: Data, error: Error?)

    var captured: URLRequest? { storage.withLock { $0 } }

    init(
        status: Int = 200,
        body: Data = Data("{}".utf8)
    ) {
        self.stub = { _ in (status, body, nil) }
    }

    init(stub: @escaping @Sendable (URLRequest) -> (status: Int, body: Data, error: Error?)) {
        self.stub = stub
    }

    func build(method: String, url: URL, headers: [String: String], body: Data?) -> Request {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        return request
    }

    func request(_ req: Request) async -> Response {
        let urlReq = req as? URLRequest ?? URLRequest(url: req.url ?? URL(string: "about:blank")!)
        storage.withLock { $0 = urlReq }
        let (status, body, error) = stub(urlReq)
        return TestResponse(request: urlReq, statusCode: status, body: body, error: error)
    }

    func request(_ req: Request, completionHandler: @escaping (Response) -> Void) {
        let urlReq = req as? URLRequest ?? URLRequest(url: req.url ?? URL(string: "about:blank")!)
        storage.withLock { $0 = urlReq }
        let (status, body, error) = stub(urlReq)
        completionHandler(TestResponse(request: urlReq, statusCode: status, body: body, error: error))
    }
}

struct TestResponse: Response {
    let request: Request?
    let statusCode: Int?
    let body: Data?
    let headers: [String: String]?
    let error: Error?

    init(request: URLRequest, statusCode: Int, body: Data, error: Error? = nil) {
        self.request = request
        self.statusCode = statusCode
        self.body = body
        self.headers = nil
        self.error = error
    }
}
