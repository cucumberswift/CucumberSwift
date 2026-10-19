//
//  Scenario.swift
//  CucumberSwiftTesting
//

import Foundation
import Testing

/// A feature, as hooks and step definitions see it.
public final class Feature {
    public let title: String
    /// The text under the feature's title, if there is any.
    public let desc: String
    public let tags: [String]
    /// The feature file's URI, as CucumberSwift's XCTest runner gives it: the `file://` URL of its copy in the
    /// test bundle, or of where its copy would be. The JSON report's `uri` is the same.
    public let uri: String
    public let location: Location
    /// The feature file's path on the Mac that built the tests, where issues are reported, so that Xcode
    /// shows them in the file you edit.
    let sourcePath: String

    init(title: String, desc: String = "", tags: [String], uri: String? = nil, sourcePath: String, location: Location = Location(line: 1, column: 1)) {
        self.title = title
        self.desc = desc
        self.tags = tags
        self.uri = uri ?? (sourcePath.contains("://") ? sourcePath : URL(fileURLWithPath: sourcePath).absoluteString)
        self.sourcePath = sourcePath
        self.location = location
    }

    /// `uri` is the feature file's copy in the test bundle; without it, the URL of its path.
    convenience init(_ scenario: GherkinScenario, uri: String? = nil) {
        self.init(title: scenario.featureTitle,
                  desc: scenario.featureDescription,
                  tags: scenario.featureTags,
                  uri: uri,
                  sourcePath: scenario.file,
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
    let internalState = ScenarioState()

    /// - Parameter feature: The scenario's feature, which the runner makes once for all its scenarios, so
    ///   that observers see one object for a feature.
    init(_ scenario: GherkinScenario, feature: Feature? = nil) {
        title = scenario.title
        tags = scenario.tags
        self.feature = feature ?? Feature(scenario)
        location = Location(line: scenario.line, column: scenario.column)
        steps = scenario.steps.map { Step($0, in: self) }
    }

    /// The running scenario's own value of type `Value`, such as the basket its steps fill in: call it from
    /// any step or scenario hook, with no scenario to pass. `make` runs the first time any step or hook of
    /// this scenario asks for a `Value`, and every later call, from any step or hook of this scenario,
    /// gets the same object. Another scenario has a value of its own, so scenarios that run at the same
    /// time don't share it. The value is released when the scenario is over.
    ///
    /// ```swift
    /// enum World {
    ///     static var basket: Basket { Scenario.state(Basket.init) }
    /// }
    ///
    /// Given("the basket has {int} cukes") { match, _ in
    ///     World.basket.cukes = try match.first(\.int)
    /// }
    /// ```
    ///
    /// `Value` is a class so that what one step changes, the next sees. Different types are different
    /// values, so one scenario can have a `Basket` and a `Beach`. Called outside a step or a scenario hook,
    /// such as from a feature hook or a task a step left running, it records a failure and returns a new
    /// value that no scenario keeps.
    public static func state<Value: AnyObject>(_ make: () -> Value) -> Value {
        guard let scenario = RunningLocation.current?.scenario else {
            Issue.record("Scenario.state(_:) needs a running scenario: call it from a step or a scenario hook.")
            return make()
        }
        return scenario.internalState.value(make)
    }
}
