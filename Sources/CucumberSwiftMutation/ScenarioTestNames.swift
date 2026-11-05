//
//  ScenarioTestNames.swift
//  CucumberSwiftMutation
//

import CucumberSwiftGherkin
import Foundation

/// Maps a scenario to the test CucumberSwift's XCTest runner generates for it, so that a runner can ask the build
/// system to run only that scenario. The names come from CucumberSwift, not from the build system, so every runner uses
/// this helper.
///
/// With a test per scenario (`CUCUMBER_ONE_TEST_PER_SCENARIO`), the test is named after the feature and the scenario,
/// as in `Voting › An adult can vote`, in the class `CucumberScenarioTest`. With a test per step, the default, the test
/// classes exist only while the bundle runs, so no build system can select one of them: `xcodebuild -only-testing` runs no
/// test, and reports success. A runner that selects scenarios turns the test per scenario on.
///
/// The helper reads the feature file with CucumberSwift's own parser and names the test with CucumberSwift's own naming
/// code (`TestNames`, linked into this module).
public struct ScenarioTestNames {
    public struct Failure: Error, Equatable, CustomStringConvertible {
        public let description: String
    }

    /// The class that holds the test of each scenario, with a test per scenario.
    public static let testClass = "CucumberScenarioTest"

    private let root: URL
    private let readable: Bool
    private let delimiter: String
    private var files = [String: [URL]]()
    private var parsed = [URL: FeatureFile]()

    /// Whether `environment` leaves CucumberSwift's readable test names on: `CUCUMBER_READABLE_TEST_NAMES` set to `NO`
    /// or `false` turns them off.
    public static func readableTestNames(in environment: [String: String]) -> Bool {
        !["no", "false"].contains((environment["CUCUMBER_READABLE_TEST_NAMES"] ?? "").lowercased())
    }

    /// The feature files under `root`, by file name, not in build folders.
    private static func featureFiles(under root: URL) -> [String: [URL]] {
        var found = [String: [URL]]()
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey]) else { return found }
        let skipped = ProjectFingerprint.ignoredFolders
        for case let url as URL in enumerator {
            if skipped.contains(url.lastPathComponent) || url.lastPathComponent.hasPrefix("bazel-") {
                enumerator.skipDescendants()
            } else if url.pathExtension == "feature" {
                found[url.lastPathComponent, default: []].append(url)
            }
        }
        return found
    }

    /// - Parameters:
    ///   - root: the folder to look for feature files in, the copy of the project.
    ///   - readable: the project's tests use readable test names, which CucumberSwift does by default. Pass what
    ///     `CUCUMBER_READABLE_TEST_NAMES` says: `ScenarioTestNames.readableTestNames(in:)` reads it from an environment.
    ///   - delimiter: the Info.plist's `FeatureScenarioDelimiter`, or `nil` for the default.
    public init(root: URL, readable: Bool = true, delimiter: String? = nil) {
        self.root = root
        self.readable = readable
        self.delimiter = delimiter ?? (readable ? TestNames.readableDelimiter : "|")
    }

    /// The names of the tests that run `scenario`: one for a scenario, and one for each row of an outline's Examples when
    /// `scenario` is the outline's line. A line inside an outline's table names that row's test.
    public mutating func testNames(for scenario: ScenarioID) throws -> [String] {
        let url = try file(for: scenario.feature)
        let feature = try parse(url)
        let prefix = TestNames.name(feature.title, readable: readable) + delimiter
        try rejectSameFeatureTitle(as: feature, besides: url)
        var counts = [String: Int]()
        var names = [String]()
        for candidate in feature.scenarios {
            // A scenario, or an outline's rows: (title, the line that selects it, whether the outline's own line does).
            let entries: [(title: String, lines: [Int])]
            if let examples = candidate.examples {
                entries = examples.map { ($0.title, $0.line == scenario.line || candidate.line == scenario.line ? [scenario.line] : []) }
            } else {
                entries = [(candidate.title, candidate.line == scenario.line ? [scenario.line] : [])]
            }
            for entry in entries {
                let base = prefix + TestNames.name(entry.title, readable: readable)
                counts[base, default: 0] += 1
                // CucumberSwift numbers a name that repeats an earlier one: `Pay 2`.
                if !entry.lines.isEmpty { names.append(counts[base] == 1 ? base : "\(base) \(counts[base] ?? 0)") }
            }
        }
        guard !names.isEmpty else {
            throw Failure(description: "\(scenario.feature) has no scenario at line \(scenario.line)")
        }
        return names
    }

    /// The tests for every scenario in `scenarios`, without repeats, in the order given.
    public mutating func testNames(for scenarios: [ScenarioID]) throws -> [String] {
        var seen = Set<String>()
        var names = [String]()
        for scenario in scenarios {
            for name in try testNames(for: scenario) where seen.insert(name).inserted { names.append(name) }
        }
        return names
    }

    /// CucumberSwift numbers a repeated name across every feature in the run, so the number of a test depends on the other
    /// feature files. Two features with one title could swap numbers, so the helper doesn't guess.
    private mutating func rejectSameFeatureTitle(as feature: FeatureFile.Feature, besides url: URL) throws {
        for other in files.values.joined() where other != url {
            if (try? parse(other))?.title == feature.title {
                let files = "\(url.lastPathComponent) and \(other.lastPathComponent)"
                throw Failure(description: "\(files) are both the feature \"\(feature.title)\", so a scenario's test name could be either one's")
            }
        }
    }

    private mutating func parse(_ url: URL) throws -> FeatureFile.Feature {
        if parsed[url] == nil {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                throw Failure(description: "Couldn't read \(url.path)")
            }
            parsed[url] = FeatureFile(parsing: text, uri: url.path)
        }
        guard let feature = parsed[url]?.features.first else { throw Failure(description: "\(url.path) has no feature") }
        return feature
    }

    /// The feature file whose path ends with `path`. Fails when none does, or when two do, because then the scenario
    /// could be either.
    private mutating func file(for path: String) throws -> URL {
        if files.isEmpty { files = Self.featureFiles(under: root) }
        let name = URL(fileURLWithPath: path).lastPathComponent
        let wanted = "/" + path.split(separator: "/").joined(separator: "/")
        let matches = (files[name] ?? []).filter { ("/" + $0.path).hasSuffix(wanted) }
        guard let match = matches.first else { throw Failure(description: "No feature file \(path) in the project") }
        guard matches.count == 1 else {
            throw Failure(description: "\(matches.count) feature files end with \(path), so the scenario could be in any of them")
        }
        return match
    }
}
