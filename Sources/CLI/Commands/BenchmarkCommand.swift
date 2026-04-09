import ArgumentParser
import AsyncRunnableCommand
import Dependencies
import Domain

extension BenchmarkScenario: ExpressibleByArgument {}

struct BenchmarkCommand: AsyncRunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "benchmark",
        abstract: "Measure CPU, memory, and energy baselines"
    )

    @Option(name: .shortAndLong, help: "Duration per scenario in seconds")
    var duration: Int = 5

    @Option(name: .shortAndLong, help: "Scenarios to run (repeatable)")
    var scenarios: [BenchmarkScenario] = []

    @Flag(help: "Output results as JSON")
    var json: Bool = false

    func run() async throws {
        @Dependency(\.benchmarkHandler) var handler
        @Dependency(\.standardOutput) var output

        if json {
            output.writeJson(await handler.measure(scenarios: scenarios, duration: Double(duration)))
        } else {
            for await update in handler.run(scenarios: scenarios, duration: Double(duration)) {
                output.write(update)
            }
        }
    }
}
