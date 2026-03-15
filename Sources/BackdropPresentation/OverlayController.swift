import BackdropDomain
import BackdropLyrics
import Dependencies
import Foundation

@MainActor
public final class OverlayController {
    public let state = OverlayState()
    private var lastTrackKey: (String?, String?) = (nil, nil)
    private var fetchGeneration: Int = 0
    private var nowPlayingTask: Task<Void, Never>?

    private var titleEffect: DecodeEffectState
    private var artistEffect: DecodeEffectState
    private var lyricEffects: [DecodeEffectState] = []

    @Dependency(\.config) private var config
    private let lyricsService = LyricsService()

    public init() {
        @Dependency(\.config) var cfg
        titleEffect = DecodeEffectState(config: cfg.text.decodeEffect)
        artistEffect = DecodeEffectState(config: cfg.text.decodeEffect)
    }
}

extension OverlayController {
    public func start() {
        nowPlayingTask = Task { [weak self] in
            guard let self else { return }
            @Dependency(\.nowPlayingProvider) var provider
            for await info in provider.stream() {
                guard !Task.isCancelled else { break }
                guard let info else { clearIfNeeded(); continue }
                updateArtwork(from: info)
                updateTrack(from: info)
                updateActiveLineIndex(from: info)
            }
        }
    }

    public func stop() {
        nowPlayingTask?.cancel()
        titleEffect.stop()
        artistEffect.stop()
        lyricEffects.forEach { $0.stop() }
    }
}

extension OverlayController {
    private func clearIfNeeded() {
        guard lastTrackKey != (nil, nil) else { return }
        lastTrackKey = (nil, nil)
        titleEffect.stop()
        artistEffect.stop()
        lyricEffects.forEach { $0.stop() }
        lyricEffects = []
        state.reset()
    }

    private func updateArtwork(from info: NowPlaying) {
        guard info.artworkData != state.artworkData else { return }
        state.artworkData = info.artworkData
    }

    private func updateTrack(from info: NowPlaying) {
        let trackKey = (info.title, info.artist)
        guard trackKey != lastTrackKey else { return }

        lastTrackKey = trackKey
        state.activeLineIndex = nil
        state.lyrics = .loading
        fetchGeneration += 1
        let generation = fetchGeneration

        // Title/artist from MediaRemote (immediate)
        revealTitle(info.title)
        revealArtist(info.artist)

        let service = lyricsService
        Task {
            let result: LyricsResult? = await {
                guard let title = info.title, let artist = info.artist else { return nil }
                return await service.fetch(title: title, artist: artist, duration: info.duration)
            }()
            guard generation == self.fetchGeneration else { return }

            // Update title/artist if LRCLib has better names
            if let trackName = result?.trackName { revealTitle(trackName) }
            if let artistName = result?.artistName { revealArtist(artistName) }

            if let content = LyricsContent(from: result) {
                revealLyrics(content)
            } else {
                state.lyrics = .failure
                lyricEffects.forEach { $0.stop() }
                lyricEffects = []
                state.displayLyricLines = []
            }
            state.activeLineIndex = nil
        }
    }

    private func updateActiveLineIndex(from info: NowPlaying) {
        guard case .success(let .timed(lines)) = state.lyrics else { return }
        guard info.playbackRate != 0 else { return }
        let index = info.elapsed.flatMap { elapsed in lines.lastIndex { $0.time <= elapsed } }
        guard index != state.activeLineIndex else { return }
        state.activeLineIndex = index
    }
}

// MARK: - Reveal animations

extension OverlayController {
    private func revealTitle(_ text: String?) {
        guard let text else { return }
        state.title = .revealing(text)
        titleEffect.onUpdate = { [weak self] displayText in
            self?.state.displayTitle = displayText
        }
        titleEffect.decode(to: text) { [weak self] in
            self?.state.title = .success(text)
        }
    }

    private func revealArtist(_ text: String?) {
        guard let text else { return }
        state.artist = .revealing(text)
        artistEffect.onUpdate = { [weak self] displayText in
            self?.state.displayArtist = displayText
        }
        artistEffect.decode(to: text) { [weak self] in
            self?.state.artist = .success(text)
        }
    }

    private func revealLyrics(_ content: LyricsContent) {
        state.lyrics = .revealing(content)
        let texts: [String] = switch content {
        case .timed(let lines): lines.map(\.text)
        case .plain(let lines): lines
        }

        lyricEffects.forEach { $0.stop() }
        lyricEffects = texts.enumerated().map { index, text in
            let effect = DecodeEffectState(config: config.text.decodeEffect)
            effect.onUpdate = { [weak self] displayText in
                guard let self, index < state.displayLyricLines.count else { return }
                state.displayLyricLines[index] = displayText
            }
            return effect
        }

        state.displayLyricLines = texts.map { _ in " " }

        for (index, text) in texts.enumerated() {
            lyricEffects[index].decode(to: text) { [weak self] in
                guard let self else { return }
                // All lines done?
                guard lyricEffects.allSatisfy({ !$0.isAnimating }) else { return }
                state.lyrics = .success(content)
            }
        }
    }
}
