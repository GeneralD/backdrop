import AIService
import ArgumentParser
import Config
import Domain
import LRCLibService
import MusicBrainzService
import Foundation
import os

struct HealthcheckCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "healthcheck",
        abstract: "Check connectivity to external services"
    )

    func run() throws {
        let result = OSAllocatedUnfairLock(initialState: Int32(0))
        let done = OSAllocatedUnfairLock(initialState: false)

        Task {
            let code = await runChecks()
            result.withLock { $0 = code }
            done.withLock { $0 = true }
        }

        while !done.withLock({ $0 }) {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
        }

        let exitCode = result.withLock { $0 }
        guard exitCode == 0 else { throw ExitCode(rawValue: exitCode) }
    }
}

private extension HealthcheckCommand {
    func runChecks() async -> Int32 {
        let config = AppConfig.load()
        printConfigStatus(config)

        let services: [any HealthCheckable] = [
            LRCLibAPI.search(query: "test"),
            MusicBrainzAPI.searchRecording(title: "test", artist: nil, duration: nil),
        ]

        var failed = 0

        for service in services {
            let result = await service.healthCheck()
            printResult(name: service.serviceName, result: result)
            if case .fail = result.status { failed += 1 }
        }

        if let aiConfig = config.ai {
            let aiService = OpenAICompatibleAPI(config: .init(
                endpoint: aiConfig.endpoint, model: aiConfig.model, apiKey: aiConfig.apiKey
            ))
            let result = await aiService.healthCheck()
            printResult(name: aiService.serviceName, result: result)
            if case .fail = result.status { failed += 1 }
        } else {
            printResult(name: "AI endpoint", result: HealthCheckResult(status: .skip, detail: "not configured"))
        }

        print("")
        switch failed {
        case 0:
            print("All checks passed.")
            return 0
        default:
            print("\(failed) check(s) failed.")
            return 1
        }
    }

    func printConfigStatus(_ config: AppConfig) {
        let home = NSHomeDirectory()
        let xdgConfig = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] ?? "\(home)/.config"
        let candidates = [
            "\(xdgConfig)/lyra/config.toml",
            "\(home)/.lyra/config.toml",
            "\(xdgConfig)/lyra/config.json",
            "\(home)/.lyra/config.json",
        ]
        let found = candidates.first { FileManager.default.fileExists(atPath: $0) }
        let detail = found.map { "loaded (\($0))" } ?? "using defaults (no config file found)"
        printResult(name: "Config", result: HealthCheckResult(status: .pass, detail: detail))
    }

    func printResult(name: String, result: HealthCheckResult) {
        let tag: String
        switch result.status {
        case .pass: tag = "[PASS]"
        case .fail: tag = "[FAIL]"
        case .skip: tag = "[SKIP]"
        }
        let padded = name.padding(toLength: 20, withPad: ".", startingAt: 0)
        print("\(tag) \(padded) \(result.detail)")
    }
}
