import ArgumentParser
import Dependencies
import Domain

struct StopCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stop",
        abstract: "Stop the running overlay"
    )

    func run() {
        @Dependency(\.processHandler) var handler
        @Dependency(\.standardOutput) var output

        switch handler.stop() {
        case .stopped:
            output.write("Stopped")
        case .notRunning:
            output.write("Not running")
        case .lockReleaseTimedOut:
            output.write("Stopped (warning: lock release timed out)")
        }
    }
}
