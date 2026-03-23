import ConfigDataSource
import Dependencies
import Domain
import Foundation

public struct ConfigRepositoryImpl {
    @Dependency(\.fontMetrics) private var fontMetrics

    public init() {}
}

extension ConfigRepositoryImpl {
    @MainActor
    public func loadAppStyle() -> AppStyle {
        let config = ConfigLoader.shared.load()
        return AppStyle(
            text: TextLayout(
                title: config.text.title.toTextAppearance(fontMetrics: fontMetrics),
                artist: config.text.artist.toTextAppearance(fontMetrics: fontMetrics),
                lyric: config.text.lyric.toTextAppearance(fontMetrics: fontMetrics),
                highlight: config.text.highlight.toTextAppearance(fontMetrics: fontMetrics),
                decodeEffect: DecodeEffect(
                    duration: config.text.decodeEffect.duration.value,
                    charsets: config.text.decodeEffect.charset
                )
            ),
            artwork: ArtworkStyle(size: config.artwork.size.value, opacity: config.artwork.opacity.value),
            ripple: RippleStyle(
                enabled: config.ripple.enabled,
                color: .solid(config.ripple.color),
                radius: config.ripple.radius.value,
                duration: config.ripple.duration.value,
                idle: config.ripple.idle.value
            ),
            screen: config.screen,
            wallpaperURL: config.wallpaper.map { URL(fileURLWithPath: $0) },
            ai: config.ai.map { AIEndpoint(endpoint: $0.endpoint, model: $0.model, apiKey: $0.apiKey) }
        )
    }
}

extension TextAppearanceConfig {
    func toTextAppearance(fontMetrics: any FontMetricsProvider) -> TextAppearance {
        let lh = MainActor.assumeIsolated {
            fontMetrics.lineHeight(fontName: fontName, fontSize: fontSize, spacing: spacing)
        }
        return TextAppearance(
            spacing: spacing,
            fontName: fontName,
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            shadow: shadow,
            lineHeight: lh
        )
    }
}
