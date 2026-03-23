import Domain
import SwiftUI

public func parseHexColor(_ hex: String) -> Color {
    let rgba = parseHexRGBA(hex)
    return Color(red: rgba.r, green: rgba.g, blue: rgba.b, opacity: rgba.a)
}

struct RGBA {
    let r: Double, g: Double, b: Double, a: Double

    var hue: Double {
        let minC = min(r, g, b)
        let maxC = max(r, g, b)
        let delta = maxC - minC
        guard delta > 0 else { return 0 }
        switch maxC {
        case r: return ((g - b) / delta).truncatingRemainder(dividingBy: 6) / 6
        case g: return ((b - r) / delta + 2) / 6
        default: return ((r - g) / delta + 4) / 6
        }
    }

    var saturation: Double {
        let maxC = max(r, g, b)
        guard maxC > 0 else { return 0 }
        return (maxC - min(r, g, b)) / maxC
    }

    var brightness: Double { max(r, g, b) }
}

func parseHexRGBA(_ hex: String) -> RGBA {
    let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
    guard let value = UInt64(h, radix: 16) else { return RGBA(r: 1, g: 1, b: 1, a: 1) }
    switch h.count {
    case 3: // RGB
        return RGBA(
            r: Double((value >> 8) & 0xF) / 15,
            g: Double((value >> 4) & 0xF) / 15,
            b: Double(value & 0xF) / 15,
            a: 1
        )
    case 6: // RRGGBB
        return RGBA(
            r: Double((value >> 16) & 0xFF) / 255,
            g: Double((value >> 8) & 0xFF) / 255,
            b: Double(value & 0xFF) / 255,
            a: 1
        )
    case 8: // RRGGBBAA
        return RGBA(
            r: Double((value >> 24) & 0xFF) / 255,
            g: Double((value >> 16) & 0xFF) / 255,
            b: Double((value >> 8) & 0xFF) / 255,
            a: Double(value & 0xFF) / 255
        )
    default:
        return RGBA(r: 1, g: 1, b: 1, a: 1)
    }
}

extension ColorStyle {
    public var shapeStyle: AnyShapeStyle {
        switch self {
        case .solid(let hex):
            return AnyShapeStyle(parseHexColor(hex))
        case .gradient(let hexColors):
            let colors = hexColors.map(parseHexColor)
            guard colors.count > 1 else {
                return .init(colors.first ?? .white)
            }
            let stops = colors.enumerated().map { i, color in
                Gradient.Stop(color: color, location: CGFloat(i) / CGFloat(colors.count - 1))
            }
            return .init(LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing))
        }
    }

    public var solidColor: Color {
        switch self {
        case .solid(let hex): parseHexColor(hex)
        case .gradient(let hexColors): parseHexColor(hexColors.first ?? "#FFFFFF")
        }
    }
}
