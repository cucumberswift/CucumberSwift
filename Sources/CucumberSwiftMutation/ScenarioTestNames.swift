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

    /// Which of CucumberSwift's runners runs a scenario's feature file.
    public enum Runner: Equatable, Sendable {
        case xctest
        case swiftTesting
    }

    /// The class that holds the test of each scenario, with a test per scenario.
    public static let testClass = "CucumberScenarioTest"
    /// The suite that holds a Swift Testing target's feature suites.
    public static let swiftTestingSuite = "CucumberFeatures"

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

    /// The runner of the feature file of `scenario`: Swift Testing when the Swift files next to the feature file, or in the
    /// nearest folder above it that has any, import `CucumberSwiftTesting`, and XCTest otherwise. The step definitions of a
    /// test target sit with its feature folder, as in `Tests/Features/Voting.feature` and `Tests/StepDefinitions.swift`.
    public mutating func runner(for scenario: ScenarioID) throws -> Runner {
        var folder = try file(for: scenario.feature).deletingLastPathComponent()
        let top = root.standardizedFileURL.pathComponents.count
        while folder.standardizedFileURL.pathComponents.count >= top {
            let swiftFiles = ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
                .filter { $0.pathExtension == "swift" }
            if !swiftFiles.isEmpty {
                let importsIt = swiftFiles.contains { ((try? String(contentsOf: $0, encoding: .utf8)) ?? "").contains("import CucumberSwiftTesting") }
                return importsIt ? .swiftTesting : .xctest
            }
            folder.deleteLastPathComponent()
        }
        return .xctest
    }

    /// The identifier, below its test target, of the Swift Testing test that runs `scenario`, as CucumberSwift's Swift
    /// Testing plugin generates it: `CucumberFeatures/Voting/AnAdultCanVote(_:)`. A scenario outline is one test, so a line in
    /// an outline names the outline. The names come from `FeatureFile`, as the plugin's do, and, as with XCTest, the helper
    /// refuses a feature title that two feature files share, because the plugin numbers a repeated suite name by the order of
    /// the target's files.
    public mutating func swiftTestingIdentifier(for scenario: ScenarioID) throws -> String {
        let url = try file(for: scenario.feature)
        let feature = try parse(url)
        try rejectSameFeatureTitle(as: feature, besides: url)
        var suites = Set<String>()
        let suite = FeatureFile.uniqueSwiftTestingName(FeatureFile.typeName(for: feature.title), fallback: "Feature", in: &suites)
        var tests = Set<String>()
        var found: String?
        for candidate in feature.scenarios {
            let name = FeatureFile.uniqueSwiftTestingName(FeatureFile.typeName(for: candidate.title), fallback: "Scenario", in: &tests)
            let lines = [candidate.line] + (candidate.examples ?? []).map(\.line)
            if lines.contains(scenario.line) { found = name }
        }
        guard let found else { throw Failure(description: "\(scenario.feature) has no scenario at line \(scenario.line)") }
        return "\(Self.swiftTestingSuite)/\(suite)/\(found)(_:)"
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
    /// feature files. Two features whose titles make one name, as `Pay now` and `Pay-now` do, could swap numbers, and the
    /// Swift Testing plugin numbers a repeated suite name by the order of the target's files, so the helper doesn't guess.
    private mutating func rejectSameFeatureTitle(as feature: FeatureFile.Feature, besides url: URL) throws {
        for other in files.values.joined() where other != url {
            guard let title = (try? parse(other))?.title, namesTheSame(title, feature.title) else { continue }
            let files = "\(url.lastPathComponent) and \(other.lastPathComponent)"
            throw Failure(description: "\(files) are the features \"\(title)\" and \"\(feature.title)\", so a scenario's test name could be either one's")
        }
    }

    /// Whether two feature titles give one test name, for either runner: the XCTest runner's, as written or in camel case,
    /// and the Swift Testing plugin's type name.
    private func namesTheSame(_ first: String, _ second: String) -> Bool {
        first == second
            || TestNames.name(first, readable: readable) == TestNames.name(second, readable: readable)
            || FeatureFile.typeName(for: first) == FeatureFile.typeName(for: second)
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
