import Dependencies

public protocol ProcessHandler: Sendable {
    func start() throws -> StartResult
    func stop() -> StopResult
    func restart() throws -> StartResult
    func acquireDaemonLock() -> Bool
}

public enum ProcessHandlerKey: TestDependencyKey {
    public static let testValue: any ProcessHandler = UnimplementedProcessHandler()
}

extension DependencyValues {
    public var processHandler: any ProcessHandler {
        get { self[ProcessHandlerKey.self] }
        set { self[ProcessHandlerKey.self] = newValue }
    }
}

private struct UnimplementedProcessHandler: ProcessHandler {
    func start() throws -> StartResult { .alreadyRunning }
    func stop() -> StopResult { .notRunning }
    func restart() throws -> StartResult { .alreadyRunning }
    func acquireDaemonLock() -> Bool { false }
}
