import Foundation

public struct WallpaperConfig: Sendable, Equatable {
    public let location: String
    public let start: TimeInterval?
    public let end: TimeInterval?

    public init(location: String, start: TimeInterval? = nil, end: TimeInterval? = nil) {
        self.location = location
        self.start = start
        self.end = end
    }
}

extension WallpaperConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case location, start, end
    }

    /// Decodes both bare string ("file.mp4") and table ({ location = "file.mp4", start = "0:30" })
    public init(from decoder: Decoder) throws {
        // Try bare string first
        if let container = try? decoder.singleValueContainer(),
            let value = try? container.decode(String.self)
        {
            location = value
            start = nil
            end = nil
            return
        }
        // Table format
        let c = try decoder.container(keyedBy: CodingKeys.self)
        location = try c.decode(String.self, forKey: .location)
        start = try c.decodeIfPresent(String.self, forKey: .start).flatMap(Self.parseTime)
        end = try c.decodeIfPresent(String.self, forKey: .end).flatMap(Self.parseTime)
    }

    public func encode(to encoder: Encoder) throws {
        guard start != nil || end != nil else {
            var container = encoder.singleValueContainer()
            try container.encode(location)
            return
        }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(location, forKey: .location)
        try c.encodeIfPresent(start.map(Self.formatTime), forKey: .start)
        try c.encodeIfPresent(end.map(Self.formatTime), forKey: .end)
    }
}

extension WallpaperConfig {
    /// Parse time string in M:SS, H:MM:SS, or fractional seconds format
    static func parseTime(_ string: String) -> TimeInterval? {
        let parts = string.split(separator: ":")
        switch parts.count {
        case 1:
            return Double(parts[0])
        case 2:
            guard let minutes = Double(parts[0]), let seconds = Double(parts[1]) else { return nil }
            return minutes * 60 + seconds
        case 3:
            guard let hours = Double(parts[0]), let minutes = Double(parts[1]), let seconds = Double(parts[2])
            else { return nil }
            return hours * 3600 + minutes * 60 + seconds
        default:
            return nil
        }
    }

    static func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let frac = interval - Double(totalSeconds)
        let base = hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
        guard frac > 0 else { return base }
        return base + String(format: ".%g", frac).dropFirst()
    }
}
