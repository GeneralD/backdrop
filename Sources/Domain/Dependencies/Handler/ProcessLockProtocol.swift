import Dependencies

public protocol ProcessLockProtocol: Sendable {
    func acquire() -> Bool
    var isLocked: Bool { get }
    func cleanup()
}

public enum ProcessLockKey: TestDependencyKey {
    public static let testValue: any ProcessLockProtocol = UnimplementedProcessLock()
}

extension DependencyValues {
    public var processLock: any ProcessLockProtocol {
        get { self[ProcessLockKey.self] }
        set { self[ProcessLockKey.self] = newValue }
    }
}

private struct UnimplementedProcessLock: ProcessLockProtocol {
    func acquire() -> Bool { false }
    var isLocked: Bool { false }
    func cleanup() {}
}
