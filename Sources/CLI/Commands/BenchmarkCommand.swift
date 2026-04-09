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

        let selected = scenarios.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        guard !selected.isEmpty else {
            output.writeError("No valid scenarios. Available: \(handler.availableScenarios.joined(separator: ", "))")
            throw ExitCode.failure
        }

        if json {
            var entries: [BenchmarkEntry] = []
            for await case .completed(let entry) in handler.run(scenarios: selected, duration: Double(duration)) {
                entries.append(entry)
            }
            output.writeJson(entries)
        } else {
            output.suppressEcho()
            defer { output.restoreEcho() }
            output.writeBenchmarkHeader()
            for await update in handler.run(scenarios: selected, duration: Double(duration)) {
                switch update {
                case .live(let entry): output.writeBenchmarkLive(entry)
                case .completed(let entry): output.writeBenchmarkResult(entry)
                }
            }
        }
    }
}
