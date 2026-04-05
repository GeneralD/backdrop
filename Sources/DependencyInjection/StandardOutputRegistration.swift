import Dependencies
import Domain

extension StandardOutputKey: DependencyKey {
    public static let liveValue: any StandardOutput = PrintStandardOutput()
}
