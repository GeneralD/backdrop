import Domain
import MediaRemoteDataSource
import Dependencies
import Foundation

public struct NowPlayingRepositoryImpl: Sendable {
    private let bridge: MediaRemoteBridge

    public init(bridge: MediaRemoteBridge) {
        self.bridge = bridge
    }
}

extension NowPlayingRepositoryImpl: NowPlayingRepository {
    public func stream() -> AsyncStream<NowPlaying?> {
        let bridge = self.bridge
        return AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    switch await bridge.poll() {
                    case .info(let nowPlaying):
                        continuation.yield(nowPlaying)
                    case .noInfo:
                        continuation.yield(nil)
                    case .eof:
                        continuation.finish()
                        return
                    }
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

// MARK: - DependencyKey

extension NowPlayingRepositoryKey: DependencyKey {
    public static let liveValue: any NowPlayingRepository = NowPlayingRepositoryImpl(bridge: MediaRemoteBridge())
}
