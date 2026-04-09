import Dependencies

public protocol BenchmarkHandler: Sendable {
    var availableScenarios: [String] { get }
    func run(scenarios: [String], duration: Double) -> AsyncStream<BenchmarkUpdate>
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
    func run(scenarios: [String], duration: Double) -> AsyncStream<BenchmarkUpdate> {
        AsyncStream { $0.finish() }
    }
}
