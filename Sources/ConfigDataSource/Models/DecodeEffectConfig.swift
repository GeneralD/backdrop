import Domain

public struct DecodeEffectConfig: Sendable {
    public let duration: FlexibleDouble
    public let charset: Set<CharsetName>
}

extension DecodeEffectConfig {
    static let defaults = DecodeEffectConfig(duration: 0.8, charset: Set(CharsetName.allCases))
}

extension DecodeEffectConfig: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        duration = try container.decodeIfPresent(FlexibleDouble.self, forKey: .duration) ?? Self.defaults.duration
        charset = try container.decodeIfPresent(Set<CharsetName>.self, forKey: .charset) ?? Self.defaults.charset
    }
}

extension Set: Encodable where Element: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Array(self))
    }
}

extension Set: Decodable where Element: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode([Element].self)
        self = Set(array)
    }
}