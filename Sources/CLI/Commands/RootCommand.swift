import AppInfo
import ArgumentParser
import Foundation

public struct RootCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "lyra",
        abstract: "Desktop lyrics overlay, video wallpaper, and more",
        version: AppInfo.version,
        subcommands: [
            StartCommand.self,
            StopCommand.self,
            RestartCommand.self,
            ServiceCommand.self,
            CompletionCommand.self,
            VersionCommand.self,
            DaemonCommand.self,
            HealthcheckCommand.self,
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
        print(RootCommand.configuration.version ?? "unknown")
    }
}
