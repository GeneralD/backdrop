import ArgumentParser
import AsyncRunnableCommand
import Dependencies
import Domain

struct BenchmarkCommand: AsyncRunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "benchmark",
        abstract: "Measure CPU, memory, and energy baselines"
    )

    @Option(name: .shortAndLong, help: "Duration per scenario in seconds")
    var duration: Int = 5

    @Option(name: .shortAndLong, help: "Scenarios to run (comma-separated: idle, cpu_spike, memory_alloc)")
    var scenarios: String = "idle,cpu_spike,memory_alloc"

    @Flag(help: "Output results as JSON")
    var json: Bool = false

    func run() async throws {
        @Dependency(\.benchmarkHandler) var handler
        @Dependency(\.standardOutput) var output

        let scenarioList = scenarios.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let result = await handler.run(scenarios: scenarioList, duration: Double(duration))

        if json, case .success(let passed) = result {
            output.writeJson(passed.entries)
        } else {
            output.write(result)
        }
        guard case .success = result else { throw ExitCode.failure }
    }
}
