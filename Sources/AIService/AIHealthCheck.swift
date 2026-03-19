import Domain
import Foundation

extension OpenAICompatibleAPI: HealthCheckable {
    public var serviceName: String { "AI endpoint" }

    public func healthCheck() async -> HealthCheckResult {
        guard let url = URL(string: normalizedEndpoint + "/models") else {
            return HealthCheckResult(status: .fail, detail: "invalid URL")
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let start = ContinuousClock.now
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let elapsed = ContinuousClock.now - start
            let ms = elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000
            guard let http = response as? HTTPURLResponse else {
                return HealthCheckResult(status: .fail, detail: "no HTTP response", latency: Double(ms) / 1000)
            }
            switch http.statusCode {
            case 200 ..< 300:
                return HealthCheckResult(status: .pass, detail: "authenticated (\(ms)ms)", latency: Double(ms) / 1000)
            case 401, 403:
                return HealthCheckResult(status: .fail, detail: "HTTP \(http.statusCode) — check api_key in [ai]", latency: Double(ms) / 1000)
            default:
                return HealthCheckResult(status: .fail, detail: "HTTP \(http.statusCode)", latency: Double(ms) / 1000)
            }
        } catch {
            return HealthCheckResult(status: .fail, detail: error.localizedDescription)
        }
    }
}
