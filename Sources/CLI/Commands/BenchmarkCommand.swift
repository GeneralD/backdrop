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

    @Option(
        name: .shortAndLong,
        help:
            "Scenarios to run (comma-separated: \(BenchmarkScenario.allCases.map(\.rawValue).joined(separator: ", ")))"
    )
    var scenarios: String = ""

    @Flag(help: "Output results as JSON")
    var json: Bool = false

    func run() async throws {
        @Dependency(\.benchmarkHandler) var handler
        @Dependency(\.standardOutput) var output

        let stream = handler.run(scenarios: parsedScenarios, duration: Double(duration))

        if json {
            var entries: [BenchmarkEntry] = []
            for await case .completed(let entry) in stream {
                entries.append(entry)
            }
            output.writeJson(entries)
        } else {
            for await update in stream {
                output.write(update)
            }
        }
    }

    private var parsedScenarios: [BenchmarkScenario] {
        guard !scenarios.isEmpty else { return [] }
        return scenarios.split(separator: ",")
            .compactMap { BenchmarkScenario(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
    }
}
