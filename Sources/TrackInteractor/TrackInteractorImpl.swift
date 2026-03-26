import Combine
import Dependencies
import Domain
import Foundation

public final class TrackInteractorImpl: @unchecked Sendable {
    @Dependency(\.playbackUseCase) private var playbackService
    @Dependency(\.lyricsUseCase) private var lyricsService
    @Dependency(\.metadataUseCase) private var metadataService
    @Dependency(\.configUseCase) private var configService

    private lazy var shared = nowPlayingPublisher.share()

    /// Emits on track change (title+artist) with metadata + lyrics resolution,
    /// and re-emits when artworkData arrives/changes for the same track.
    public lazy var trackChange: AnyPublisher<TrackUpdate, Never> = {
        let trackChanged =
            shared
            .compactMap { $0 }
            .removeDuplicates { $0.title == $1.title && $0.artist == $1.artist }
            .flatMap { [weak self] info -> AnyPublisher<TrackUpdate, Never> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                return resolveTrack(from: info)
            }

        let artworkChanged =
            shared
            .compactMap { $0 }
            .removeDuplicates { $0.artworkData == $1.artworkData }
            .compactMap { $0.artworkData }

        // Carry latest artwork into resolved track updates
        return
            trackChanged
            .combineLatest(artworkChanged.prepend(Data()))
            .map { update, artwork in
                TrackUpdate(
                    title: update.title,
                    artist: update.artist,
                    artworkData: artwork.isEmpty ? nil : artwork,
                    duration: update.duration,
                    lyrics: update.lyrics,
                    lyricsState: update.lyricsState
                )
            }
            .removeDuplicates {
                $0.title == $1.title && $0.artist == $1.artist
                    && $0.artworkData == $1.artworkData && $0.lyricsState == $1.lyricsState
            }
            .share()
            .eraseToAnyPublisher()
    }()

    /// Playback position: every NowPlaying update, just elapsed + rate.
    public lazy var playbackPosition: AnyPublisher<PlaybackPosition, Never> =
        shared
        .compactMap { $0 }
        .map { PlaybackPosition(elapsed: $0.elapsed, playbackRate: $0.playbackRate) }
        .eraseToAnyPublisher()

    public init() {}
}

extension TrackInteractorImpl: TrackInteractor {
    public var decodeEffectConfig: DecodeEffect {
        configService.loadAppStyle().text.decodeEffect
    }

    public var textLayout: TextLayout {
        configService.loadAppStyle().text
    }

    public var artworkStyle: ArtworkStyle {
        configService.loadAppStyle().artwork
    }
}

extension TrackInteractorImpl {
    private var nowPlayingPublisher: AnyPublisher<NowPlaying?, Never> {
        let playback = playbackService
        return Deferred {
            let pub = PassthroughSubject<NowPlaying?, Never>()
            nonisolated(unsafe) let sendable = pub
            let task = Task {
                for await info in playback.observeNowPlaying() {
                    guard !Task.isCancelled else { break }
                    sendable.send(info)
                }
                sendable.send(completion: .finished)
            }
            return pub.handleEvents(receiveCancel: { task.cancel() })
        }
        .eraseToAnyPublisher()
    }

    private func resolveTrack(from info: NowPlaying) -> AnyPublisher<TrackUpdate, Never> {
        let loading = TrackUpdate(
            title: info.title,
            artist: info.artist,
            artworkData: info.artworkData,
            duration: info.duration,
            lyricsState: .loading
        )

        guard let title = info.title, let artist = info.artist else {
            return Just(loading).eraseToAnyPublisher()
        }

        let rawTrack = Track(title: title, artist: artist, duration: info.duration)
        let metadata = metadataService
        let lyrics = lyricsService

        return Just(loading)
            .append(
                Deferred {
                    Future<TrackUpdate, Never> { promise in
                        nonisolated(unsafe) let promise = promise
                        Task {
                            let candidates = await metadata.resolveCandidates(track: rawTrack)
                            let resolvedTitle = candidates.first?.title ?? title
                            let resolvedArtist =
                                candidates.first.map(\.artist).flatMap { $0.isEmpty ? nil : $0 } ?? artist

                            let result =
                                candidates.isEmpty
                                ? await lyrics.fetchLyrics(track: rawTrack)
                                : await lyrics.fetchLyrics(candidates: candidates)

                            let finalTitle = result.trackName ?? resolvedTitle
                            let finalArtist = result.artistName ?? resolvedArtist
                            let content = LyricsContent(from: result)

                            promise(
                                .success(
                                    TrackUpdate(
                                        title: finalTitle,
                                        artist: finalArtist,
                                        artworkData: info.artworkData,
                                        duration: info.duration,
                                        lyrics: content,
                                        lyricsState: content != nil ? .resolved : .notFound
                                    )))
                        }
                    }
                }
                .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            )
            .eraseToAnyPublisher()
    }
}
