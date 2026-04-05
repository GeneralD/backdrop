import Dependencies

public protocol ServiceHandler: Sendable {
    func install() throws -> ServiceInstallResult
    func uninstall() throws -> ServiceUninstallResult
}

public enum ServiceHandlerKey: TestDependencyKey {
    public static let testValue: any ServiceHandler = UnimplementedServiceHandler()
}

extension DependencyValues {
    public var serviceHandler: any ServiceHandler {
        get { self[ServiceHandlerKey.self] }
        set { self[ServiceHandlerKey.self] = newValue }
    }
}

private struct UnimplementedServiceHandler: ServiceHandler {
    func install() throws -> ServiceInstallResult { fatalError("ServiceHandler.install not implemented") }
    func uninstall() throws -> ServiceUninstallResult { fatalError("ServiceHandler.uninstall not implemented") }
}
