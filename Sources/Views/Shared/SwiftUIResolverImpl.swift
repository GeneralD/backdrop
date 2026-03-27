import Dependencies
import Domain
import SwiftUI

// MARK: - RGBA

private struct RGBA {
    let r: Double, g: Double, b: Double, a: Double

    static let white = RGBA(r: 1, g: 1, b: 1, a: 1)

    init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    var color: Color { Color(red: r, green: g, blue: b, opacity: a) }

    var hsb: (hue: Double, saturation: Double, brightness: Double) {
        let maxC = max(r, g, b)
        let delta = maxC - min(r, g, b)
        let hue: Double =
            delta == 0
            ? 0
            : maxC == r
                ? (((g - b) / delta).truncatingRemainder(dividingBy: 6)) / 6
                : maxC == g
                    ? ((b - r) / delta + 2) / 6
                    : ((r - g) / delta + 4) / 6
        let saturation = maxC == 0 ? 0 : delta / maxC
        return (hue < 0 ? hue + 1 : hue, saturation, maxC)
    }

    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard let value = UInt64(h, radix: 16) else {
            self = .white
            return
        }
        switch h.count {
        case 3:
            self.init(
                r: Double((value >> 8) & 0xF) / 15,
                g: Double((value >> 4) & 0xF) / 15,
                b: Double(value & 0xF) / 15, a: 1)
        case 6:
            self.init(
                r: Double((value >> 16) & 0xFF) / 255,
                g: Double((value >> 8) & 0xFF) / 255,
                b: Double(value & 0xFF) / 255, a: 1)
        case 8:
            self.init(
                r: Double((value >> 24) & 0xFF) / 255,
                g: Double((value >> 16) & 0xFF) / 255,
                b: Double((value >> 8) & 0xFF) / 255,
                a: Double(value & 0xFF) / 255)
        default:
            self = .white
        }
    }
}

// MARK: - Live Implementation

public struct SwiftUIResolverImpl: SwiftUIResolver {
    public init() {}

    @MainActor public func font(from style: TextAppearance) -> Font {
        let weight: Font.Weight =
            switch style.fontWeight.lowercased() {
            case "ultralight": .ultraLight
            case "thin": .thin
            case "light": .light
            case "medium": .medium
            case "semibold": .semibold
            case "bold": .bold
            case "heavy": .heavy
            case "black": .black
            default: .regular
            }
        return Font.custom(style.fontName, size: style.fontSize).weight(weight)
    }

    @MainActor public func color(from hex: String) -> Color {
        RGBA(hex: hex).color
    }

    @MainActor public func solidColor(from style: ColorStyle) -> Color {
        switch style {
        case .solid(let hex): color(from: hex)
        case .gradient(let hexColors): color(from: hexColors.first ?? "#FFFFFF")
        }
    }

    @MainActor public func shapeStyle(from style: ColorStyle) -> AnyShapeStyle {
        switch style {
        case .solid(let hex):
            return AnyShapeStyle(color(from: hex))
        case .gradient(let hexColors):
            let colors = hexColors.map { color(from: $0) }
            guard colors.count > 1 else {
                return .init(colors.first ?? .white)
            }
            let stops = colors.enumerated().map { i, c in
                Gradient.Stop(color: c, location: CGFloat(i) / CGFloat(colors.count - 1))
            }
            return .init(LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing))
        }
    }

    @MainActor public func color(
        _ style: ColorStyle, hueShiftedBy shift: Double, opacity: Double
    ) -> Color {
        let hex: String =
            switch style {
            case .solid(let h): h
            case .gradient(let colors): colors.first ?? "#FFFFFF"
            }
        let hsb = RGBA(hex: hex).hsb
        return Color(
            hue: (hsb.hue + shift).truncatingRemainder(dividingBy: 1),
            saturation: hsb.saturation,
            brightness: hsb.brightness,
            opacity: opacity
        )
    }

    @MainActor public func hsbComponents(from style: ColorStyle) -> (hue: Double, saturation: Double, brightness: Double) {
        let hex: String =
            switch style {
            case .solid(let h): h
            case .gradient(let colors): colors.first ?? "#FFFFFF"
            }
        return RGBA(hex: hex).hsb
    }

    @MainActor public func lineHeight(from style: TextAppearance) -> Double {
        @Dependency(\.fontMetrics) var fontMetrics
        return fontMetrics.lineHeight(
            fontName: style.fontName, fontSize: style.fontSize, spacing: style.spacing
        )
    }
}
