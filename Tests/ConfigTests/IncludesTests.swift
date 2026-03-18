import Domain
import Foundation
import Testing
import TOMLKit

@testable import Config

@Suite("Config includes")
struct IncludesTests {
    private let tempDir: String = NSTemporaryDirectory() + "lyra-config-test-\(UUID().uuidString)"

    private func setUp(mainToml: String, files: [String: String] = [:]) throws -> String {
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        let mainPath = tempDir + "/config.toml"
        try mainToml.write(toFile: mainPath, atomically: true, encoding: .utf8)
        for (name, content) in files {
            try content.write(toFile: tempDir + "/\(name)", atomically: true, encoding: .utf8)
        }
        return mainPath
    }

    private func tearDown() {
        try? FileManager.default.removeItem(atPath: tempDir)
    }

    @Test("loads AI config from included file")
    func aiConfigFromInclude() throws {
        defer { tearDown() }

        let mainPath = try setUp(
            mainToml: """
                includes = ["ai.toml"]
                screen = "main"
                """,
            files: [
                "ai.toml": """
                    [ai]
                    endpoint = "https://example.com/v1"
                    model = "test-model"
                    api_key = "test-key"
                    """,
            ]
        )

        let content = try String(contentsOfFile: mainPath, encoding: .utf8)
        let table = try TOMLTable(string: content)
        let configDir = (mainPath as NSString).deletingLastPathComponent

        resolveIncludes(into: table, configDir: configDir)
        table.remove(at: "includes")

        let config = try TOMLDecoder().decode(AppConfig.self, from: table)
        #expect(config.ai != nil)
        #expect(config.ai?.endpoint == "https://example.com/v1")
        #expect(config.ai?.model == "test-model")
        #expect(config.ai?.apiKey == "test-key")
    }

    @Test("main config takes precedence over included")
    func mainOverridesInclude() throws {
        defer { tearDown() }

        let mainPath = try setUp(
            mainToml: """
                includes = ["base.toml"]
                screen = "match"
                """,
            files: [
                "base.toml": """
                    screen = "main"
                    """,
            ]
        )

        let content = try String(contentsOfFile: mainPath, encoding: .utf8)
        let table = try TOMLTable(string: content)
        let configDir = (mainPath as NSString).deletingLastPathComponent

        resolveIncludes(into: table, configDir: configDir)
        table.remove(at: "includes")

        let config = try TOMLDecoder().decode(AppConfig.self, from: table)
        #expect(config.screen == ScreenSelector.match)
    }

    @Test("no includes section works fine")
    func noIncludes() throws {
        defer { tearDown() }

        let mainPath = try setUp(mainToml: """
            screen = "main"
            """)

        let content = try String(contentsOfFile: mainPath, encoding: .utf8)
        let table = try TOMLTable(string: content)
        let configDir = (mainPath as NSString).deletingLastPathComponent

        resolveIncludes(into: table, configDir: configDir)
        table.remove(at: "includes")

        let config = try TOMLDecoder().decode(AppConfig.self, from: table)
        #expect(config.screen == ScreenSelector.main)
        #expect(config.ai == nil)
    }
}
