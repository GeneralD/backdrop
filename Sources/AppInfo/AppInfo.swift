import Foundation

public enum AppInfo {
    public static let version: String = {
        guard let url = Bundle.module.url(forResource: "version", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else { return "unknown" }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }()

    public static let userAgent = "lyra/\(version) (https://github.com/GeneralD/lyra)"
}
