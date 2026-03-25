import Foundation

public struct YouTubeWallpaper: Sendable {
    public let url: URL
    public let maxHeight: Int
    public let format: String

    public init(url: URL, maxHeight: Int = 1080, format: String = "mp4") {
        self.url = url
        self.maxHeight = maxHeight
        self.format = format
    }
}
