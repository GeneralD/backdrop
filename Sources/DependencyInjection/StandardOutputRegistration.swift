import Dependencies
import Domain
import Foundation

extension StandardOutputKey: DependencyKey {
    public static let liveValue: any StandardOutput = PrintStandardOutput()
}

private struct PrintStandardOutput: StandardOutput {
    func write(_ message: String) { print(message) }
    func writeError(_ message: String) { fputs(message + "\n", stderr) }

    // MARK: - Process

    func output(_ result: StartResult) {
        switch result {
        case .success(.started(let pid)): write("Overlay started (PID \(pid))")
        case .failure(.alreadyRunning): writeError("Already running")
        case .failure(.daemonExitedImmediately): writeError("Failed to start (daemon exited immediately)")
        case .failure(.spawnFailed(let detail)): writeError("Failed to start: \(detail)")
        }
    }

    func output(_ result: StopResult) {
        switch result {
        case .success(.stopped): write("Stopped")
        case .success(.notRunning): write("Not running")
        case .failure(.lockReleaseTimedOut): writeError("Stopped (warning: lock release timed out)")
        }
    }

    // MARK: - Service

    func output(_ result: ServiceInstallResult) {
        switch result {
        case .success(.installed(let path)): write("Installed and started: \(path)")
        case .failure(.managedByHomebrew):
            writeError("Already managed by brew services. Run 'brew services stop lyra' first.")
        case .failure(.bootstrapFailed(let status)): writeError("Bootstrap failed (status \(status))")
        case .failure(.failed(let detail)): writeError("Install failed: \(detail)")
        }
    }

    func output(_ result: ServiceUninstallResult) {
        switch result {
        case .success(.uninstalled): write("Uninstalled")
        case .failure(.managedByHomebrew):
            writeError("Managed by brew services. Run 'brew services stop lyra' instead.")
        case .failure(.notInstalled): writeError("Not installed")
        case .failure(.failed(let detail)): writeError("Uninstall failed: \(detail)")
        }
    }

    // MARK: - Config

    func output(_ result: ConfigWriteResult) {
        switch result {
        case .success(.created(let path)): write("Config file created at \(path)")
        case .failure(.failed(let detail)): writeError("Config error: \(detail)")
        }
    }

    func output(_ result: ConfigPathResult) {
        switch result {
        case .success(.found(let path)): write(path)
        case .failure(.failed(let detail)): writeError("Config error: \(detail)")
        }
    }
}
