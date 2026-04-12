import Dependencies
import Presenters
import Views

/// Wireframe: creates Presenters, builds window, manages lifecycle.
@MainActor
public final class AppRouter {
    private let bootstrap: AppDependencyBootstrap
    private var appPresenter: AppPresenter?
    private var headerPresenter: HeaderPresenter?
    private var lyricsPresenter: LyricsPresenter?
    private var wallpaperPresenter: WallpaperPresenter?
    private var ripplePresenter: RipplePresenter?

    private var appWindow: AppWindow?
    private var displayLinkDriver: DisplayLinkDriver?

    public init(launchEnvironment: AppLaunchEnvironment = .current) {
        self.bootstrap = AppDependencyBootstrap(launchEnvironment: launchEnvironment)
    }

    public func start() {
        let appPresenter = make { AppPresenter() }
        let headerPresenter = make { HeaderPresenter() }
        let lyricsPresenter = make { LyricsPresenter() }
        let wallpaperPresenter = make { WallpaperPresenter() }
        self.appPresenter = appPresenter
        self.headerPresenter = headerPresenter
        self.lyricsPresenter = lyricsPresenter
        self.wallpaperPresenter = wallpaperPresenter

        appPresenter.start()
        let ripplePresenter = make {
            RipplePresenter(screenOrigin: appPresenter.layout.screenOrigin)
        }
        self.ripplePresenter = ripplePresenter

        headerPresenter.start()
        lyricsPresenter.start()
        ripplePresenter.start()
        wallpaperPresenter.start()

        let window = AppWindow(
            appPresenter: appPresenter,
            wallpaperPresenter: wallpaperPresenter,
            headerPresenter: headerPresenter,
            lyricsPresenter: lyricsPresenter,
            ripplePresenter: ripplePresenter
        )
        appWindow = window

        let driver = DisplayLinkDriver { [weak self] in
            self?.ripplePresenter?.idle()
            self?.lyricsPresenter?.updateActiveLineTick()
        }
        self.displayLinkDriver = driver
        driver.start(in: window)
    }

    public func stop() {
        headerPresenter?.stop()
        lyricsPresenter?.stop()
        wallpaperPresenter?.stop()
        ripplePresenter?.stop()
        displayLinkDriver?.stop()
        appWindow?.orderOut(nil)
        appWindow?.close()
        appWindow = nil
    }

    private func make<T>(_ operation: () -> T) -> T {
        withDependencies {
            bootstrap.apply(to: &$0)
        } operation: {
            operation()
        }
    }
}
