import Dependencies

public protocol BenchmarkHandler: Sendable {
    var availableScenarios: [String] { get }
    func measure(scenario: String, duration: Double) async -> BenchmarkEntry
    var currentMetrics: ProcessMetrics { get }
}

public enum BenchmarkHandlerKey: TestDependencyKey {
    public static let testValue: any BenchmarkHandler = UnimplementedBenchmarkHandler()
}

extension DependencyValues {
    public var benchmarkHandler: any BenchmarkHandler {
        get { self[BenchmarkHandlerKey.self] }
        set { self[BenchmarkHandlerKey.self] = newValue }
    }
}

private struct UnimplementedBenchmarkHandler: BenchmarkHandler {
    var availableScenarios: [String] { [] }
    func measure(scenario: String, duration: Double) async -> BenchmarkEntry {
        fatalError("BenchmarkHandler.measure not implemented")
    }
    var currentMetrics: ProcessMetrics {
        ProcessMetrics(cpuUser: 0, cpuSystem: 0, rssBytes: 0, peakRSSBytes: 0)
    }
}
