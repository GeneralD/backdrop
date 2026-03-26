import Foundation

public struct TrackUpdate {
    public let title: String?
    public let artist: String?
    public let artworkData: Data?
    public let duration: TimeInterval?
    public let elapsed: TimeInterval?
    public let playbackRate: Double
    public let lyrics: LyricsContent?
    public let lyricsState: TrackLyricsState

    public init(
        title: String? = nil,
        artist: String? = nil,
        artworkData: Data? = nil,
        duration: TimeInterval? = nil,
        elapsed: TimeInterval? = nil,
        playbackRate: Double = 1.0,
        lyrics: LyricsContent? = nil,
        lyricsState: TrackLyricsState = .idle
    ) {
        self.title = title
        self.artist = artist
        self.artworkData = artworkData
        self.duration = duration
        self.elapsed = elapsed
        self.playbackRate = playbackRate
        self.lyrics = lyrics
        self.lyricsState = lyricsState
    }
}

extension TrackUpdate: Sendable {}
