import Dependencies
import Domain
import Presenters
import Testing

@testable import App

@Suite("AppLaunchEnvironment")
struct AppLaunchEnvironmentTests {
    @Test("parses UI test launch environment and lyrics lines")
    func parsesEnvironment() {
        let environment = AppLaunchEnvironment(
            environment: [
                "LYRA_UI_TEST_MODE": "true",
                "LYRA_UI_TEST_TITLE": "Test Song",
                "LYRA_UI_TEST_ARTIST": "Test Artist",
                "LYRA_UI_TEST_LYRICS": "Line 1\nLine 2\n\nLine 3",
            ]
        )

        #expect(environment.isUITestMode)
        #expect(environment.title == "Test Song")
        #expect(environment.artist == "Test Artist")
        #expect(environment.lyricsLines == ["Line 1", "Line 2", "Line 3"])
    }

    @Test("uses stable defaults when environment is missing")
    func defaults() {
        let environment = AppLaunchEnvironment(environment: [:])

        #expect(!environment.isUITestMode)
        #expect(environment.title == "UI Test Song")
        #expect(environment.artist == "UI Test Artist")
        #expect(environment.lyricsLines == ["First UI test lyric", "Second UI test lyric"])
    }
}

@MainActor
@Suite("AppDependencyBootstrap")
struct AppDependencyBootstrapTests {
    @Test("injects fixture track data for presenters in UI test mode")
    func injectsFixtureTrackData() async {
        let bootstrap = AppDependencyBootstrap(
            launchEnvironment: .init(
                environment: [
                    "LYRA_UI_TEST_MODE": "1",
                    "LYRA_UI_TEST_TITLE": "Bootstrap Song",
                    "LYRA_UI_TEST_ARTIST": "Bootstrap Artist",
                    "LYRA_UI_TEST_LYRICS": "Alpha\nBeta",
                ]
            )
        )

        let headerPresenter = withDependencies {
            bootstrap.apply(to: &$0)
        } operation: {
            HeaderPresenter()
        }
        let lyricsPresenter = withDependencies {
            bootstrap.apply(to: &$0)
        } operation: {
            LyricsPresenter()
        }

        headerPresenter.start()
        lyricsPresenter.start()
        await Task.yield()
        await Task.yield()

        #expect(headerPresenter.displayTitle == "Bootstrap Song")
        #expect(headerPresenter.displayArtist == "Bootstrap Artist")
        #expect(lyricsPresenter.displayLyricLines == ["Alpha", "Beta"])
        #expect(lyricsPresenter.lyricsState == .success(.plain(["Alpha", "Beta"])))
    }
}
