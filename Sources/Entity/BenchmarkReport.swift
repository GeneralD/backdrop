public struct ProcessMetrics: Sendable {
    public let cpuUser: Double
    public let cpuSystem: Double
    public let rssBytes: Int64
    public let peakRSSBytes: Int64

    public init(cpuUser: Double, cpuSystem: Double, rssBytes: Int64, peakRSSBytes: Int64) {
        self.cpuUser = cpuUser
        self.cpuSystem = cpuSystem
        self.rssBytes = rssBytes
        self.peakRSSBytes = peakRSSBytes
    }
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
