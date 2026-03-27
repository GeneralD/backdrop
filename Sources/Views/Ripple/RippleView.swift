import Dependencies
import Domain
import Presenters
import SwiftUI

@MainActor
public struct RippleView: View {
    let presenter: RipplePresenter

    public init(presenter: RipplePresenter) {
        self.presenter = presenter
    }

    public var body: some View {
        if presenter.isEnabled, presenter.rippleState != nil {
            rippleCanvas
        }
    }

    private var rippleCanvas: some View {
        @Dependency(\.swiftUIResolver) var resolver
        let baseHSB = resolver.hsbComponents(from: presenter.rippleConfig.color)

        return TimelineView(.animation) { timeline in
            Canvas { context, size in
                let commands = presenter.rippleDrawCommands(
                    canvasSize: size, baseHSB: baseHSB, now: timeline.date)
                for cmd in commands {
                    let rect = CGRect(
                        x: cmd.center.x - cmd.radius, y: cmd.center.y - cmd.radius,
                        width: cmd.radius * 2, height: cmd.radius * 2)
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(
                            Color(
                                hue: cmd.hue, saturation: cmd.saturation,
                                brightness: cmd.brightness, opacity: cmd.opacity)),
                        lineWidth: 2.5
                    )
                }
            }
        }
    }
}

#if DEBUG
    #Preview("Ripple") {
        RippleView(presenter: RipplePresenter())
            .frame(width: 400, height: 300)
            .background(.black)
    }
#endif
