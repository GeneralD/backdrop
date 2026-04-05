import ArgumentParser
import Dependencies
import Domain

struct ServiceCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "service",
        abstract: "Manage login item service",
        subcommands: [Install.self, Uninstall.self]
    )

    struct Install: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Register as login item (LaunchAgent)"
        )

        func run() throws {
            @Dependency(\.serviceHandler) var handler
            switch try handler.install() {
            case .installed(let path):
                print("Installed and started: \(path)")
            case .managedByHomebrew:
                print("Already managed by brew services. Run 'brew services stop lyra' first.")
            case .bootstrapFailed(let status):
                print("Bootstrap failed (status \(status))")
                throw ExitCode.failure
            }
        }
    }

    struct Uninstall: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Remove login item"
        )

        func run() throws {
            @Dependency(\.serviceHandler) var handler
            switch try handler.uninstall() {
            case .uninstalled:
                print("Uninstalled")
            case .managedByHomebrew:
                print("Managed by brew services. Run 'brew services stop lyra' instead.")
            case .notInstalled:
                print("Not installed")
            }
        }
    }
}
