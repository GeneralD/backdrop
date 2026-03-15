import BackdropConfig
import BackdropDomain
import BackdropPresentation
import Dependencies
import SwiftUI

@MainActor
public struct HeaderView: View {
    let state: OverlayState

    @Dependency(\.config) private var config

    public init(state: OverlayState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: 24) {
            if let artworkData = state.artworkData, let image = NSImage(data: artworkData) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: config.artwork.size)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            VStack(alignment: .leading, spacing: config.text.title.spacing) {
                Text(state.displayTitle)
                    .font(makeFont(style: config.text.title))
                    .foregroundStyle(config.text.title.color.shapeStyle)
                    .shadow(color: config.text.title.shadow.solidColor, radius: 5, x: 0, y: 1)
                    .lineLimit(1)
                Text(state.displayArtist)
                    .font(makeFont(style: config.text.artist))
                    .foregroundStyle(config.text.artist.color.shapeStyle)
                    .shadow(color: config.text.artist.shadow.solidColor, radius: 5, x: 0, y: 1)
                    .lineLimit(1)
            }
            Spacer()
        }
    }
}
