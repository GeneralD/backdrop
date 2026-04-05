public enum ServiceInstallResult: Sendable {
    case installed(path: String)
    case managedByHomebrew
    case bootstrapFailed(status: Int32)
}

public enum ServiceUninstallResult: Sendable {
    case uninstalled
    case managedByHomebrew
    case notInstalled
}
