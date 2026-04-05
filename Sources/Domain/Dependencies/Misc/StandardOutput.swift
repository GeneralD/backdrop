import Dependencies

public protocol StandardOutput: Sendable {
    func write(_ message: String)
}

public enum StandardOutputKey: TestDependencyKey {
    public static let testValue: any StandardOutput = UnimplementedStandardOutput()
}

extension DependencyValues {
    public var standardOutput: any StandardOutput {
        get { self[StandardOutputKey.self] }
        set { self[StandardOutputKey.self] = newValue }
    }
}

private struct UnimplementedStandardOutput: StandardOutput {
    func write(_ message: String) { fatalError("StandardOutput.write not implemented") }
}
