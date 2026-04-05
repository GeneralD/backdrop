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
    func acquire() -> Bool { fatalError("ProcessLock.acquire not implemented") }
    var isLocked: Bool { fatalError("ProcessLock.isLocked not implemented") }
    func cleanup() { fatalError("ProcessLock.cleanup not implemented") }
}
