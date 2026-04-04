import ArgumentParser
import Foundation

struct StartCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start the overlay as a background process"
    )

    func run() throws {
        guard !ProcessLock.shared.isLocked, ProcessManager.findOverlayPIDs().isEmpty else {
            print("Already running")
            return
        }

        let executablePath = Bundle.main.executablePath ?? CommandLine.arguments[0]
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executablePath)
        task.arguments = ["daemon"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try task.run()

        // Wait briefly to detect immediate exit (e.g. lock contention)
        usleep(500_000)
        guard task.isRunning else {
            print("Failed to start (daemon exited immediately)")
            throw ExitCode.failure
        }
        print("Overlay started (PID \(task.processIdentifier))")
    }
}

struct RestartCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "restart",
        abstract: "Stop and start the overlay"
    )

    func run() throws {
        ProcessManager.stopExisting()
        let start = StartCommand()
        try start.run()
    }
}
