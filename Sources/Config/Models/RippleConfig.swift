import Foundation

public struct RippleConfig: Sendable {
    public let enabled: Bool
    public let color: String
    public let radius: Double
    public let duration: Double
    public let idle: Double
}

extension RippleConfig {
    static let defaults = RippleConfig(enabled: true, color: "#AAAAFFFF", radius: 60, duration: 0.6, idle: 1)
}

extension RippleConfig: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? Self.defaults.enabled
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? Self.defaults.color
        radius = try container.flexibleDouble(forKey: .radius) ?? Self.defaults.radius
        duration = try container.flexibleDouble(forKey: .duration) ?? Self.defaults.duration
        idle = try container.flexibleDouble(forKey: .idle) ?? Self.defaults.idle
    }
}
