//
//  Scenario.swift
//  CucumberSwiftTesting
//

import Foundation

/// A feature, as hooks and step definitions see it.
public final class Feature {
    public let title: String
    public let tags: [String]
    /// The feature file's path on the Mac that built the tests.
    public let uri: String

    init(title: String, tags: [String], uri: String) {
        self.title = title
        self.tags = tags
        self.uri = uri
    }
}

/// A scenario, or one example of a Scenario Outline, as hooks and step definitions see it.
public final class Scenario {
    public let title: String
    /// The feature's tags, then the scenario's.
    public let tags: [String]
    /// The Background's steps, then the scenario's.
    public private(set) var steps = [Step]()
    public let feature: Feature?
    public let location: Location

    init(_ scenario: GherkinScenario) {
        title = scenario.title
        tags = scenario.tags
        feature = Feature(title: scenario.featureTitle, tags: scenario.featureTags, uri: scenario.file)
        location = Location(line: scenario.line, column: scenario.column)
        steps = scenario.steps.map { Step($0, in: self) }
    }
}
