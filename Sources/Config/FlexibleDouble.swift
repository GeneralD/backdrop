/// A Double that decodes from both Int and Double in TOML/JSON.
public struct FlexibleDouble: Sendable, Hashable {
    public let value: Double

    public init(_ value: Double) {
        self.value = value
    }
}

extension FlexibleDouble: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Double.self) {
            value = d
        } else {
            value = Double(try container.decode(Int.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension FlexibleDouble: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.value = value
    }
}

extension FlexibleDouble: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.value = Double(value)
    }
}

// MARK: - KeyedDecodingContainer helpers (for configs using raw Double)

extension KeyedDecodingContainer {
    func flexibleDouble(forKey key: Key) throws -> Double? {
        guard contains(key) else { return nil }
        if let d = try? decodeIfPresent(Double.self, forKey: key) { return d }
        if let i = try? decodeIfPresent(Int.self, forKey: key) { return Double(i) }
        return nil
    }
}
