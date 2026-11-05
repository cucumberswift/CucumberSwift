//
//  ScenarioTestNames.swift
//  CucumberSwiftMutation
//

import CucumberSwiftGherkin
import Foundation

/// Maps a scenario to the tests CucumberSwift generates for it, so that a runner can ask the build system to
/// run only that scenario. Every runner uses it, because the names come from CucumberSwift, not from the build system.
///
/// CucumberSwift's XCTest runner makes a class for each scenario, named after the feature and the scenario
/// (`Voting|AnAdultCanVote`), with a test for each step. The helper reads the feature file with CucumberSwift's own
/// parser and names the class with CucumberSwift's own naming code (`TestNames`, linked into this module).
public struct ScenarioTestNames {
    public struct Failure: Error, Equatable, CustomStringConvertible {
        public let description: String
    }

    private let root: URL
    private let readable: Bool
    private let delimiter: String
    private var files = [String: [URL]]()
    private var parsed = [URL: FeatureFile]()

    /// - Parameters:
    ///   - root: the folder to look for feature files in, the copy of the project.
    ///   - readable: the project's tests use readable test names (`CUCUMBER_READABLE_TEST_NAMES`).
    ///   - delimiter: the Info.plist's `FeatureScenarioDelimiter`, or `nil` for the default.
    public init(root: URL, readable: Bool = false, delimiter: String? = nil) {
        self.root = root
        self.readable = readable
        self.delimiter = delimiter ?? (readable ? TestNames.readableDelimiter : "|")
    }

    /// The names of the classes that run `scenario`: one for a scenario, and one for each row of an outline's
    /// Examples when `scenario` is the outline's line. A line inside an outline's table names that row's class.
    public mutating func classNames(for scenario: ScenarioID) throws -> [String] {
        let url = try file(for: scenario.feature)
        let feature = try parse(url)
        let featureName = TestNames.name(feature.title, readable: readable)
        var names = [String]()
        for candidate in feature.scenarios {
            if let examples = candidate.examples {
                if candidate.line == scenario.line {
                    names += examples.map { $0.title }
                } else {
                    names += examples.filter { $0.line == scenario.line }.map { $0.title }
                }
            } else if candidate.line == scenario.line {
                names.append(candidate.title)
            }
        }
        guard !names.isEmpty else {
            throw Failure(description: "\(scenario.feature) has no scenario at line \(scenario.line)")
        }
        return names.map { featureName + delimiter + TestNames.name($0, readable: readable) }
    }

    /// The classes for every scenario in `scenarios`, without repeats, in the order given.
    public mutating func classNames(for scenarios: [ScenarioID]) throws -> [String] {
        var seen = Set<String>()
        var names = [String]()
        for scenario in scenarios {
            for name in try classNames(for: scenario) where seen.insert(name).inserted { names.append(name) }
        }
        return names
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
        let name = (path as NSString).lastPathComponent
        let wanted = "/" + path.split(separator: "/").joined(separator: "/")
        let matches = (files[name] ?? []).filter { ("/" + $0.path).hasSuffix(wanted) }
        guard let match = matches.first else { throw Failure(description: "No feature file \(path) in the project") }
        guard matches.count == 1 else {
            throw Failure(description: "\(matches.count) feature files end with \(path), so the scenario could be in any of them")
        }
        return match
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
}
