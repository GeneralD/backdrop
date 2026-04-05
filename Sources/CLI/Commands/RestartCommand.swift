import ArgumentParser

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
