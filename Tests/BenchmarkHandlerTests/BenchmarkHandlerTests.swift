import Entity
import Foundation
import Testing

@testable import BenchmarkHandler

@Suite("BenchmarkHandlerImpl")
struct BenchmarkHandlerTests {
    @Test("idle scenario returns non-negative CPU and memory values")
    func idleScenario() async {
        let handler = BenchmarkHandlerImpl()
        let result = await handler.run(scenarios: ["idle"], duration: 1)

        guard case .success(let passed) = result else {
            Issue.record("Expected success but got failure")
            return
        }
        #expect(passed.entries.count == 1)

        let entry = passed.entries[0]
        #expect(entry.scenario == "idle")
        #expect(entry.durationSeconds >= 1.0)
        #expect(entry.cpuUserSeconds >= 0)
        #expect(entry.cpuSystemSeconds >= 0)
        #expect(entry.currentRSSBytes > 0)
        #expect(entry.peakRSSBytes > 0)
    }

    @Test("invalid scenario returns failure")
    func invalidScenario() async {
        let handler = BenchmarkHandlerImpl()
        let result = await handler.run(scenarios: ["nonexistent"], duration: 1)

        guard case .failure(let failed) = result else {
            Issue.record("Expected failure but got success")
            return
        }
        #expect(failed.detail.contains("No valid scenarios"))
    }

    @Test("multiple scenarios run sequentially")
    func multipleScenarios() async {
        let handler = BenchmarkHandlerImpl()
        let result = await handler.run(scenarios: ["idle", "idle"], duration: 1)

        guard case .success(let passed) = result else {
            Issue.record("Expected success but got failure")
            return
        }
        #expect(passed.entries.count == 2)
        #expect(passed.entries.allSatisfy { $0.scenario == "idle" })
    }

    @Test("cpu_spike scenario shows higher CPU than idle")
    func cpuSpikeHigherThanIdle() async {
        let handler = BenchmarkHandlerImpl()
        let result = await handler.run(scenarios: ["idle", "cpu_spike"], duration: 1)

        guard case .success(let passed) = result else {
            Issue.record("Expected success but got failure")
            return
        }
        let idle = passed.entries[0]
        let spike = passed.entries[1]
        #expect(spike.cpuUserSeconds > idle.cpuUserSeconds)
    }

    @Test("BenchmarkEntry encodes to JSON")
    func entryEncodesToJson() throws {
        let entry = BenchmarkEntry(
            scenario: "test",
            durationSeconds: 1.0,
            cpuUserSeconds: 0.5,
            cpuSystemSeconds: 0.1,
            peakRSSBytes: 1024,
            currentRSSBytes: 512
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(BenchmarkEntry.self, from: data)
        #expect(decoded.scenario == "test")
        #expect(decoded.durationSeconds == 1.0)
    }

    @Test("empty scenarios defaults to all available")
    func emptyScenariosDefaultsToAll() async {
        let handler = BenchmarkHandlerImpl()
        let result = await handler.run(scenarios: [], duration: 1)

        guard case .success(let passed) = result else {
            Issue.record("Expected success but got failure")
            return
        }
        #expect(passed.entries.count == 3)
    }
}
