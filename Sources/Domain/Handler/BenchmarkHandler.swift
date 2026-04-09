import Dependencies

public protocol BenchmarkHandler: Sendable {
    func run(scenarios: [String], duration: Double) async -> BenchmarkReport
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
    func run(scenarios: [String], duration: Double) async -> BenchmarkReport {
        fatalError("BenchmarkHandler.run not implemented")
    }
}
