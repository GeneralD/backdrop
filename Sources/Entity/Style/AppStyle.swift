import Foundation

public struct AppStyle: Sendable {
    public let text: TextLayout
    public let artwork: ArtworkStyle
    public let ripple: RippleStyle
    public let screen: ScreenSelector
    public let wallpaper: String?
    public let wallpaperStart: TimeInterval?
    public let wallpaperEnd: TimeInterval?
    public let configDir: String?
    public let ai: AIEndpoint?

    public init(
        text: TextLayout = .init(),
        artwork: ArtworkStyle = .init(),
        ripple: RippleStyle = .init(),
        screen: ScreenSelector = .main,
        wallpaper: String? = nil,
        wallpaperStart: TimeInterval? = nil,
        wallpaperEnd: TimeInterval? = nil,
        configDir: String? = nil,
        ai: AIEndpoint? = nil
    ) {
        self.text = text
        self.artwork = artwork
        self.ripple = ripple
        self.screen = screen
        self.wallpaper = wallpaper
        self.wallpaperStart = wallpaperStart
        self.wallpaperEnd = wallpaperEnd
        self.configDir = configDir
        self.ai = ai
    }
}
