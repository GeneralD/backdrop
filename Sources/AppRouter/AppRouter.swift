import CoreGraphics
import Dependencies
import Domain
import Presenters
import Views

/// Wireframe: creates Presenters, builds window, manages lifecycle.
@MainActor
public final class AppRouter {
    private let bootstrap: AppDependencyBootstrap
    private let windowFactory: @MainActor (ScreenLayout, HeaderPresenter, LyricsPresenter, RipplePresenter) -> any OverlayWindow
    private let frameSchedulerFactory: @MainActor (@escaping @MainActor () -> Void) -> any FrameScheduler
    private var appPresenter: AppPresenter?
    private var headerPresenter: HeaderPresenter?
    private var lyricsPresenter: LyricsPresenter?
    private var wallpaperPresenter: WallpaperPresenter?
    private var ripplePresenter: RipplePresenter?

    private var appWindow: (any OverlayWindow)?
    private var frameScheduler: (any FrameScheduler)?

    public convenience init(launchEnvironment: AppLaunchEnvironment = .current) {
        self.init(
            bootstrap: AppDependencyBootstrap(launchEnvironment: launchEnvironment),
            windowFactory: { layout, headerPresenter, lyricsPresenter, ripplePresenter in
                AppWindow(
                    initialLayout: layout,
                    headerPresenter: headerPresenter,
                    lyricsPresenter: lyricsPresenter,
                    ripplePresenter: ripplePresenter
                )
            },
            frameSchedulerFactory: { onFrame in
                DisplayLinkDriver(onFrame: onFrame)
            }
        )
    }

    convenience init(
        launchEnvironment: AppLaunchEnvironment,
        windowFactory: @escaping @MainActor (ScreenLayout, HeaderPresenter, LyricsPresenter, RipplePresenter) -> any OverlayWindow,
        frameSchedulerFactory: @escaping @MainActor (@escaping @MainActor () -> Void) -> any FrameScheduler
    ) {
        self.init(
            bootstrap: AppDependencyBootstrap(launchEnvironment: launchEnvironment),
            windowFactory: windowFactory,
            frameSchedulerFactory: frameSchedulerFactory
        )
    }

    init(
        bootstrap: AppDependencyBootstrap,
        windowFactory: @escaping @MainActor (ScreenLayout, HeaderPresenter, LyricsPresenter, RipplePresenter) -> any OverlayWindow,
        frameSchedulerFactory: @escaping @MainActor (@escaping @MainActor () -> Void) -> any FrameScheduler
    ) {
        self.bootstrap = bootstrap
        self.windowFactory = windowFactory
        self.frameSchedulerFactory = frameSchedulerFactory
    }

    public func start() {
        guard appWindow == nil, frameScheduler == nil else { return }

        withBootstrap {
            let appPresenter = AppPresenter()
            let headerPresenter = HeaderPresenter()
            let lyricsPresenter = LyricsPresenter()
            let wallpaperPresenter = WallpaperPresenter()
            self.appPresenter = appPresenter
            self.headerPresenter = headerPresenter
            self.lyricsPresenter = lyricsPresenter
            self.wallpaperPresenter = wallpaperPresenter

            appPresenter.start()
            let layout = appPresenter.layout
            let ripplePresenter = RipplePresenter(
                screenRect: CGRect(origin: layout.screenOrigin, size: layout.hostingFrame.size))
            self.ripplePresenter = ripplePresenter

            headerPresenter.start()
            lyricsPresenter.start()
            ripplePresenter.start()
            wallpaperPresenter.start()

            let window = windowFactory(layout, headerPresenter, lyricsPresenter, ripplePresenter)
            appWindow = window

            appPresenter.bind(ripplePresenter: ripplePresenter)
            appPresenter.onWindowFrameChange { [weak window] layout in
                window?.applyLayout(layout)
            }
            wallpaperPresenter.onPlayerAvailable { [weak window] player in
                window?.attachPlayerLayer(for: player)
            }

            let scheduler = frameSchedulerFactory { [weak self] in
                self?.ripplePresenter?.idle()
                self?.lyricsPresenter?.updateActiveLineTick()
            }
            self.frameScheduler = scheduler
            scheduler.start(in: window)
        }
    }

    public func stop() {
        guard appWindow != nil || frameScheduler != nil else { return }

        appPresenter?.stop()
        headerPresenter?.stop()
        lyricsPresenter?.stop()
        wallpaperPresenter?.stop()
        ripplePresenter?.stop()
        frameScheduler?.stop()
        appWindow?.orderOut(nil)
        appWindow?.close()
        frameScheduler = nil
        appWindow = nil
        ripplePresenter = nil
        wallpaperPresenter = nil
        lyricsPresenter = nil
        headerPresenter = nil
        appPresenter = nil
    }

    private func withBootstrap<T>(_ operation: () -> T) -> T {
        withDependencies {
            bootstrap.apply(to: &$0)
        } operation: {
            operation()
        }
    }
}
