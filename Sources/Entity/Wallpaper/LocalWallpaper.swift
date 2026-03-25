public struct LocalWallpaper: Sendable {
    public let path: String
    public let configDir: String

    public init(path: String, configDir: String) {
        self.path = path
        self.configDir = configDir
    }
}
