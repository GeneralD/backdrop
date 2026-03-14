import SwiftHEXColors
import SwiftUI

public func parseHexColor(_ hex: String) -> Color {
    guard let nsColor = NSColor(hexString: hex) else { return .white }
    return Color(nsColor: nsColor)
}
