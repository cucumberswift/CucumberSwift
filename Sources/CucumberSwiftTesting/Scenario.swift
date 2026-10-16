//
//  Scenario.swift
//  CucumberSwiftTesting
//

import Foundation

/// A feature, as hooks and step definitions see it.
public final class Feature {
    public let title: String
    /// The text under the feature's title, if there is any.
    public let desc: String
    public let tags: [String]
    /// The feature file's path on the Mac that built the tests.
    public let uri: String
    public let location: Location

    init(title: String, desc: String = "", tags: [String], uri: String, location: Location = Location(line: 1, column: 1)) {
        self.title = title
        self.desc = desc
        self.tags = tags
        self.uri = uri
        self.location = location
    }

    convenience init(_ scenario: GherkinScenario) {
        self.init(title: scenario.featureTitle,
                  desc: scenario.featureDescription,
                  tags: scenario.featureTags,
                  uri: scenario.file,
                  location: Location(line: scenario.featureLine, column: 1))
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

    /// - Parameter feature: The scenario's feature, which the runner makes once for all its scenarios, so
    ///   that observers see one object for a feature.
    init(_ scenario: GherkinScenario, feature: Feature? = nil) {
        title = scenario.title
        tags = scenario.tags
        self.feature = feature ?? Feature(scenario)
        location = Location(line: scenario.line, column: scenario.column)
        steps = scenario.steps.map { Step($0, in: self) }
    }
}
