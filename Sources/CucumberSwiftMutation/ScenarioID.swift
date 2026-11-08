//
//  ScenarioID.swift
//  CucumberSwiftMutation
//

import Foundation

/// A scenario, by its feature file's path inside the test bundle and its line, so that the scenario of a run in the
/// throwaway copy matches the same scenario in the package's own runs, where the bundle is somewhere else.
public struct ScenarioID: Hashable, Comparable, Sendable {
    /// The feature file's path inside the test bundle, such as `Features/Basket.feature`.
    public let feature: String
    public let line: Int
    public let name: String

    /// The ID in the Stryker report: `Features/Basket.feature:12`.
    public var id: String { "\(feature):\(line)" }

    /// The path of the feature file at `uri` inside its test bundle: after the last `.xctest/`, where Xcode puts the
    /// feature files, or `.bundle/`, where SwiftPM puts a target's resources. The whole path when it has neither.
    /// A macOS or Mac Catalyst bundle keeps its resources in `Contents/Resources`, which is left out, so that the path
    /// is the same on every platform. CucumberSwift reads the same way in `MutationReport`, and the two must agree.
    public static func feature(ofURI uri: String) -> String {
        let path = uri.hasPrefix("file:") ? (URL(string: uri)?.path ?? uri) : uri
        let marker = [".xctest/", ".bundle/"].compactMap { path.range(of: $0, options: .backwards) }.max { $0.upperBound < $1.upperBound }
        guard let marker else { return path }
        let inBundle = path[marker.upperBound...]
        let resources = "Contents/Resources/"
        return String(inBundle.hasPrefix(resources) ? inBundle.dropFirst(resources.count) : inBundle)
    }

    public static func < (lhs: ScenarioID, rhs: ScenarioID) -> Bool {
        (lhs.feature, lhs.line) < (rhs.feature, rhs.line)
    }

    public init(feature: String, line: Int, name: String) {
        self.feature = feature
        self.line = line
        self.name = name
    }

    /// The scenario of the feature file at `uri`, a path or a `file:` URL, as CucumberSwift reports it.
    public init(uri: String, line: Int, name: String) {
        self.init(feature: Self.feature(ofURI: uri), line: line, name: name)
    }
}

extension ScenarioID: CustomStringConvertible {
    /// `Two items pay shipping (line 5)`
    public var description: String { "\(name) (line \(line))" }
}
