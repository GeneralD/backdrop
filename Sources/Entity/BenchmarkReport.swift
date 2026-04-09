public typealias BenchmarkReport = Result<BenchmarkPassed, BenchmarkFailed>

public struct BenchmarkPassed: Sendable {
    public let entries: [BenchmarkEntry]
    public init(entries: [BenchmarkEntry]) { self.entries = entries }
}

public struct BenchmarkFailed: Error, Sendable {
    public let detail: String
    public init(detail: String) { self.detail = detail }
}

public struct BenchmarkEntry: Sendable, Codable {
    public let scenario: String
    public let durationSeconds: Double
    public let cpuUserSeconds: Double
    public let cpuSystemSeconds: Double
    public let peakRSSBytes: Int64
    public let currentRSSBytes: Int64

    public init(
        scenario: String,
        durationSeconds: Double,
        cpuUserSeconds: Double,
        cpuSystemSeconds: Double,
        peakRSSBytes: Int64,
        currentRSSBytes: Int64
    ) {
        self.scenario = scenario
        self.durationSeconds = durationSeconds
        self.cpuUserSeconds = cpuUserSeconds
        self.cpuSystemSeconds = cpuSystemSeconds
        self.peakRSSBytes = peakRSSBytes
        self.currentRSSBytes = currentRSSBytes
    }
}
