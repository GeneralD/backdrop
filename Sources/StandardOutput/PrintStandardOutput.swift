import Darwin.POSIX
import Domain
import Foundation

public struct PrintStandardOutput: StandardOutput {
    public init() {}
    public func write(_ message: String) { print(message) }
    public func writeError(_ message: String) { fputs(message + "\n", stderr) }

    public func writeJson(_ value: some Encodable & Sendable) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return }
        write(String(data: data, encoding: .utf8) ?? "{}")
    }

    // MARK: - Process

    public func write(_ result: StartResult) {
        switch result {
        case .success(.started(let pid)): write("Overlay started (PID \(pid))")
        case .failure(.alreadyRunning): writeError("Already running")
        case .failure(.daemonExitedImmediately): writeError("Failed to start (daemon exited immediately)")
        case .failure(.spawnFailed(let detail)): writeError("Failed to start: \(detail)")
        case .failure(.stopFailed): writeError("Failed to restart (could not stop existing process)")
        }
    }

    public func write(_ result: StopResult) {
        switch result {
        case .success(.stopped): write("Stopped")
        case .success(.notRunning): write("Not running")
        case .failure(.lockReleaseTimedOut): writeError("Stopped (warning: lock release timed out)")
        }
    }

    // MARK: - Service

    public func write(_ result: ServiceInstallResult) {
        switch result {
        case .success(.installed(let path)): write("Installed and started: \(path)")
        case .failure(.managedByHomebrew):
            writeError("Already managed by brew services. Run 'brew services stop lyra' first.")
        case .failure(.bootstrapFailed(let status)): writeError("Bootstrap failed (status \(status))")
        case .failure(.failed(let detail)): writeError("Install failed: \(detail)")
        }
    }

    public func write(_ result: ServiceUninstallResult) {
        switch result {
        case .success(.uninstalled): write("Uninstalled")
        case .failure(.managedByHomebrew):
            writeError("Managed by brew services. Run 'brew services stop lyra' instead.")
        case .failure(.notInstalled): writeError("Not installed")
        case .failure(.failed(let detail)): writeError("Uninstall failed: \(detail)")
        }
    }

    // MARK: - Health

    public func write(_ result: HealthCheckReport) {
        let entries: [HealthReportEntry]
        switch result {
        case .success(let passed): entries = passed.entries
        case .failure(let failed): entries = failed.entries
        }

        for entry in entries {
            let tag: String
            switch entry.result.status {
            case .pass: tag = "[PASS]"
            case .fail: tag = "[FAIL]"
            case .skip: tag = "[SKIP]"
            }
            write("\(tag) \(entry.serviceName.padding(toLength: 20, withPad: ".", startingAt: 0)) \(entry.result.detail)")
        }

        write("")
        switch result {
        case .success: write("All checks passed.")
        case .failure(let failed): writeError("\(failed.failedCount) check(s) failed.")
        }
    }

    // MARK: - Config

    public func write(_ result: ConfigWriteResult) {
        switch result {
        case .success(.created(let path)): write("Config file created at \(path)")
        case .failure(.failed(let detail)): writeError("Config error: \(detail)")
        }
    }

    public func write(_ result: ConfigPathResult) {
        switch result {
        case .success(.found(let path)): write(path)
        case .failure(.failed(let detail)): writeError("Config error: \(detail)")
        }
    }

    // MARK: - Benchmark

    public func writeBenchmark(
        handler: any BenchmarkHandler, scenarios: [String], duration: Double
    ) async {
        var old = termios()
        tcgetattr(STDIN_FILENO, &old)
        var raw = old
        raw.c_lflag &= ~UInt(ECHO | ICANON)
        tcsetattr(STDIN_FILENO, TCSANOW, &raw)
        defer { tcsetattr(STDIN_FILENO, TCSANOW, &old) }

        writeHeader()

        for scenario in scenarios {
            let baseline = handler.currentMetrics
            let start = ContinuousClock.now

            let entry: BenchmarkEntry = await withTaskGroup(of: BenchmarkEntry?.self) { group in
                group.addTask {
                    await handler.measure(scenario: scenario, duration: duration)
                }
                group.addTask {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .milliseconds(250))
                        guard !Task.isCancelled else { break }
                        let (s, a) = start.duration(to: .now).components
                        let elapsed = Double(s) + Double(a) / 1_000_000_000_000_000_000
                        writeLive(
                            scenario: scenario, elapsed: elapsed,
                            metrics: handler.currentMetrics, baseline: baseline)
                    }
                    return nil
                }
                var result: BenchmarkEntry!
                for await r in group {
                    guard let r else { continue }
                    result = r
                    group.cancelAll()
                    break
                }
                return result
            }
            writeRow(entry)
        }
    }

    private func writeHeader() {
        let header =
            "Scenario".padding(toLength: 16, withPad: " ", startingAt: 0)
            + "Duration".padding(toLength: 10, withPad: " ", startingAt: 0)
            + "CPU(user)".padding(toLength: 11, withPad: " ", startingAt: 0)
            + "CPU(sys)".padding(toLength: 11, withPad: " ", startingAt: 0)
            + "RSS(MB)".padding(toLength: 10, withPad: " ", startingAt: 0)
            + "Peak(MB)"
        write(header)
        write(String(repeating: "─", count: header.count))
    }

    private func writeRow(_ entry: BenchmarkEntry) {
        let padded = formatRow(
            scenario: entry.scenario,
            duration: entry.durationSeconds,
            cpuUser: entry.cpuUserSeconds,
            cpuSystem: entry.cpuSystemSeconds,
            rss: entry.currentRSSBytes,
            peak: entry.peakRSSBytes
        ).padding(toLength: 80, withPad: " ", startingAt: 0)
        print("\r\(padded)")
    }

    private func writeLive(
        scenario: String, elapsed: Double, metrics: ProcessMetrics, baseline: ProcessMetrics
    ) {
        let padded = formatRow(
            scenario: scenario,
            duration: elapsed,
            cpuUser: metrics.cpuUser - baseline.cpuUser,
            cpuSystem: metrics.cpuSystem - baseline.cpuSystem,
            rss: metrics.rssBytes,
            peak: metrics.peakRSSBytes
        ).padding(toLength: 80, withPad: " ", startingAt: 0)
        print("\r\(padded)", terminator: "")
        fflush(stdout)
    }

    private func formatRow(
        scenario: String, duration: Double, cpuUser: Double, cpuSystem: Double, rss: Int64, peak: Int64
    ) -> String {
        scenario.padding(toLength: 16, withPad: " ", startingAt: 0)
            + formatted(seconds: duration).padding(toLength: 10, withPad: " ", startingAt: 0)
            + formatted(seconds: cpuUser).padding(toLength: 11, withPad: " ", startingAt: 0)
            + formatted(seconds: cpuSystem).padding(toLength: 11, withPad: " ", startingAt: 0)
            + formatted(megabytes: rss).padding(toLength: 10, withPad: " ", startingAt: 0)
            + formatted(megabytes: peak)
    }

    private func formatted(seconds: Double) -> String {
        String(format: "%.3fs", seconds)
    }

    private func formatted(megabytes bytes: Int64) -> String {
        String(format: "%.1f", Double(bytes) / 1_048_576)
    }
}
