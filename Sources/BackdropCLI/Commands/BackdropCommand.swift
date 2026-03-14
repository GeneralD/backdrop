import ArgumentParser

public struct BackdropCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "backdrop",
        abstract: "Desktop backdrop — lyrics overlay, video wallpaper, and more",
        version: "1.0.0",
        subcommands: [
            StartCommand.self,
            StopCommand.self,
            RestartCommand.self,
            ServiceCommand.self,
            CompletionCommand.self,
            VersionCommand.self,
            DaemonCommand.self,
        ],
        defaultSubcommand: StartCommand.self
    )

    public init() {}
}

struct VersionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Show version"
    )

    func run() {
        print(BackdropCommand.configuration.version ?? "unknown")
    }
}
