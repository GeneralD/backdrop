import ArgumentParser
import Foundation

let appVersion: String = {
    guard let url = Bundle.module.url(forResource: "version", withExtension: "txt"),
        let content = try? String(contentsOf: url, encoding: .utf8)
    else { return "unknown" }
    return content.trimmingCharacters(in: .whitespacesAndNewlines)
}()

struct VersionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Show version"
    )

    func run() {
        print(appVersion)
    }
}
