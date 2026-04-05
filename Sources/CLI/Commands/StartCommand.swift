import ArgumentParser
import Dependencies
import Domain

struct StartCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start the overlay as a background process"
    )

    func run() throws {
        @Dependency(\.processHandler) var handler

        switch try handler.start() {
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
