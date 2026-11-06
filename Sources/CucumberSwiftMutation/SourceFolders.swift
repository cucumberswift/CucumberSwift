//
//  SourceFolders.swift
//  CucumberSwiftMutation
//

import Foundation

/// The folders whose Swift files a run mutates, read from `swift package describe --type json`: those of the
/// package's library and executable targets. Test targets are never mutated.
public enum SourceFolders {
    public struct DescribeError: Error, Equatable, CustomStringConvertible {
        public let description: String
    }

    struct Target: Decodable, Equatable {
        let name: String
        let type: String
        let path: String
    }

    private struct Description: Decodable {
        let targets: [Target]
    }

    /// The target types whose code a run mutates.
    static let mutatedTypes: Set<String> = ["library", "executable"]

    /// The folders, relative to `root`, of the targets named in `names`, or of every target with code when `names` is
    /// empty. A named test target is left out, because its code isn't mutated: Xcode names every target of the package,
    /// test targets included, when it runs the command.
    public static func find(in root: URL, named names: [String], swift: String, runner: CommandRunning) throws -> [String] {
        let result = runner.run(swift, ["package", "describe", "--type", "json"], in: root, environment: [:], timeout: 300)
        guard result.status == 0 else {
            throw DescribeError(description: "`swift package describe` failed in \(root.path):\n\(result.output)")
        }
        return try folders(describedBy: Data(result.output.utf8), named: names)
    }

    /// The folders that `find` returns, from the JSON that `swift package describe --type json` prints.
    static func folders(describedBy json: Data, named names: [String]) throws -> [String] {
        // SwiftPM may print warnings before the JSON, such as an unused dependency.
        let start = json.firstIndex(of: UInt8(ascii: "{")) ?? json.startIndex
        guard let description = try? JSONDecoder().decode(Description.self, from: json[start...]) else {
            throw DescribeError(description: "`swift package describe` printed no package description")
        }
        let unknown = names.filter { name in !description.targets.contains { $0.name == name } }
        guard unknown.isEmpty else {
            throw DescribeError(description: "No target named \(unknown.joined(separator: ", "))")
        }
        let withCode = description.targets.filter { mutatedTypes.contains($0.type) }
        let chosen = withCode.filter { names.isEmpty || names.contains($0.name) }
        guard !chosen.isEmpty else { throw DescribeError(description: "The package has no target with code to mutate") }
        return chosen.map(\.path)
    }
}
