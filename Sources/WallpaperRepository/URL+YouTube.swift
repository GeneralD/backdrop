import Foundation

extension URL {
    var isYouTube: Bool {
        guard let host = host?.lowercased() else { return false }
        return host.contains("youtube.com") || host.contains("youtu.be")
    }
}
