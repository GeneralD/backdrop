import Dependencies
import Domain

extension RandomSourceKey: DependencyKey {
    public static let liveValue: any RandomSource = SystemRandomSource()
}

public struct SystemRandomSource: RandomSource {
    public init() {}
    public func next(below count: Int) -> Int {
        .random(in: 0..<count)
    }
}
