import BackdropDomain
import BackdropMediaRemote
import Dependencies
import Foundation

public struct NowPlayingService: NowPlayingProvider, Sendable {
    private let bridge: MediaRemoteBridge

    public init(bridge: MediaRemoteBridge) {
        self.bridge = bridge
    }
}

extension NowPlayingService {
    public func stream() -> AsyncStream<NowPlaying?> {
        let bridge = self.bridge
        return AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    let info = await bridge.poll()
                    continuation.yield(info.map(NowPlaying.init(from:)))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

extension NowPlaying {
    init(from info: MediaRemoteInfo) {
        self.init(
            title: info.title,
            artist: info.artist,
            artworkData: info.artworkData,
            duration: info.duration,
            rawElapsed: info.rawElapsed,
            playbackRate: info.playbackRate,
            timestamp: info.timestamp
        )
    }
}

// MARK: - DependencyKey

extension NowPlayingProviderKey: DependencyKey {
    public static let liveValue: any NowPlayingProvider = NowPlayingService(bridge: MediaRemoteBridge())
}
