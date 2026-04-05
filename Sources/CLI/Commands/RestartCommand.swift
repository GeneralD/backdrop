import ArgumentParser
import Dependencies
import Domain

struct RestartCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "restart",
        abstract: "Stop and start the overlay"
    )

    func run() throws {
        @Dependency(\.processHandler) var handler

        switch try handler.restart() {
        case .started(let pid):
            print("Overlay started (PID \(pid))")
        case .alreadyRunning:
            print("Already running")
        case .daemonExitedImmediately:
            print("Failed to start (daemon exited immediately)")
            throw ExitCode.failure
        }
    }
}
