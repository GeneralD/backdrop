import Dependencies
import Domain

public struct HealthHandlerImpl: HealthHandler {
    public init() {}

    public func check() async -> HealthReport {
        @Dependency(\.healthCheckers) var checkers
        let checkerList = checkers

        let entries = await withTaskGroup(
            of: (Int, HealthReport.Entry).self,
            returning: [HealthReport.Entry].self
        ) { group in
            for (index, checker) in checkerList.enumerated() {
                group.addTask {
                    let result = await checker.healthCheck()
                    return (index, HealthReport.Entry(serviceName: checker.serviceName, result: result))
                }
            }
            var results: [(Int, HealthReport.Entry)] = []
            for await pair in group { results.append(pair) }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }

        return HealthReport(entries: entries)
    }
}
