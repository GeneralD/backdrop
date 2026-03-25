import Foundation

public struct RemoteWallpaper: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }
}
