public enum ConfigFormat: String, CaseIterable, Sendable {
    case toml
    case json

    public var fileExtension: String { rawValue }
}
