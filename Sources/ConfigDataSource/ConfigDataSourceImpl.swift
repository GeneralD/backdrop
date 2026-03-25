import Domain
import Foundation
import TOMLKit

public struct ConfigDataSourceImpl: Sendable {
    public init() {}
}

extension ConfigDataSourceImpl: ConfigDataSource {
    public func load() -> ConfigLoadResult? {
        guard let (path, content) = findConfigFile() else { return nil }
        let configDir = URL(fileURLWithPath: path).deletingLastPathComponent().path
        guard let config = decode(content: content, path: path, configDir: configDir) else { return nil }
        return ConfigLoadResult(config: config, configDir: configDir, path: path)
    }

    public func template(format: ConfigFormat) -> String? {
        let config = AppConfig.defaults
        switch format {
        case .toml:
            return try? TOMLEncoder().encode(config)
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let data = try? encoder.encode(config) else { return nil }
            return String(data: data, encoding: .utf8)
        }
    }

    public func writeTemplate(format: ConfigFormat, force: Bool) throws -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let xdgConfig = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] ?? "\(home)/.config"
        let dir = "\(xdgConfig)/lyra"
        let path = "\(dir)/config.\(format.fileExtension)"

        guard force || !FileManager.default.fileExists(atPath: path) else {
            throw ConfigWriteError.alreadyExists(path: path)
        }

        guard let content = template(format: format) else {
            throw ConfigWriteError.encodingFailed
        }

        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    public func tryDecode() throws -> String {
        guard let (path, content) = findConfigFile() else { return "" }
        let configDir = URL(fileURLWithPath: path).deletingLastPathComponent().path
        try decodeOrThrow(content: content, path: path, configDir: configDir)
        return path
    }
}

extension ConfigDataSourceImpl {
    func findConfigFile() -> (path: String, content: String)? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let xdgConfig = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] ?? "\(home)/.config"
        let candidates = [
            "\(xdgConfig)/lyra/config.toml",
            "\(home)/.lyra/config.toml",
            "\(xdgConfig)/lyra/config.json",
            "\(home)/.lyra/config.json",
        ]
        guard let path = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }),
            let content = try? String(contentsOfFile: path, encoding: .utf8)
        else { return nil }
        return (path, content)
    }

    @discardableResult
    func decodeOrThrow(content: String, path: String, configDir: String) throws -> AppConfig {
        guard path.hasSuffix(".toml") else {
            return try JSONDecoder().decode(AppConfig.self, from: content.data(using: .utf8) ?? Data())
        }
        let table = try TOMLTable(string: content)
        resolveIncludes(into: table, configDir: configDir)
        table.remove(at: "includes")
        return try TOMLDecoder().decode(AppConfig.self, from: table)
    }

    func decode(content: String, path: String, configDir: String) -> AppConfig? {
        try? decodeOrThrow(content: content, path: path, configDir: configDir)
    }

    func resolveIncludes(into table: TOMLTable, configDir: String) {
        guard let paths = table["includes"]?.array else { return }
        for element in paths {
            guard let relativePath = element.string else { continue }
            let absolutePath =
                relativePath.hasPrefix("/")
                ? relativePath
                : URL(fileURLWithPath: configDir).appendingPathComponent(relativePath).path
            guard let content = try? String(contentsOfFile: absolutePath, encoding: .utf8),
                let included = try? TOMLTable(string: content)
            else { continue }
            deepMerge(from: included, into: table)
        }
    }

    func deepMerge(from source: TOMLTable, into target: TOMLTable) {
        for (key, value) in source {
            guard let sourceTable = value.table,
                let targetTable = target[key]?.table
            else {
                if target[key] == nil { target[key] = value }
                continue
            }
            deepMerge(from: sourceTable, into: targetTable)
        }
    }
}
