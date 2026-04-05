import Dependencies
import Domain

extension StandardOutputKey: DependencyKey {
    public static let liveValue: any StandardOutput = PrintStandardOutput()
}

private struct PrintStandardOutput: StandardOutput {
    func write(_ message: String) { print(message) }
}
