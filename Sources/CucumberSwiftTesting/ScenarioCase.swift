//
//  ScenarioCase.swift
//  CucumberSwiftTesting
//
// What the generated tests run. A scenario's test is parameterized, because Swift Testing names its tests with
// literals when they build, and names a test case when they run, which is when `Cucumber.readableTestNames`
// and `Cucumber.oneTestPerScenario` are known. With CucumberSwift's default, a test for each step, each case
// is a step; with `oneTestPerScenario`, the scenario is one case. They are public only so that the generated
// code, which is compiled into your test target, can use them.

import Foundation
import Testing

/// One test case of a scenario's test: the whole scenario, or one of its steps.
public struct ScenarioCase: Sendable, CustomTestStringConvertible, CustomTestArgumentEncodable {
    public let scenario: GherkinScenario
    /// The step this case runs, or `nil` when it runs the whole scenario.
    let stepIndex: Int?
    let name: String

    /// How Xcode and `swift test` name the case, as CucumberSwift names a test: `3 › Then the total is 99`, or
    /// with readable test names off, `Step002_ThenTheTotalIs99`. An example of a Scenario Outline adds
    /// `Example (line 7)` before it, and a scenario that is one test is `Scenario (line 3)` or the example's.
    public var testDescription: String { name }

    /// Identifies the case by its line and step, not its name, so that Xcode runs it again when a setting
    /// renames it or a value in an example's row changes.
    public func encodeTestArgument(to encoder: some Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(scenario.line):\(stepIndex ?? -1)")
    }
}

extension Cucumber {
    /// The cases of a plain scenario, and of an example of a Scenario Outline: one for each step, or one for the
    /// scenario with ``Cucumber/oneTestPerScenario``. Swift Testing asks when it discovers the tests, so the
    /// step definitions are set up first, in case `setupSteps()` sets one of the settings.
    func cases(of scenario: GherkinScenario, label: String?) -> [ScenarioCase] {
        loadStepDefinitions()
        let readable = CucumberSettings.isReadableTestNames(environment: environment)
        guard !CucumberSettings.isOneTestPerScenario(environment: environment), !scenario.steps.isEmpty else {
            return [ScenarioCase(scenario: scenario, stepIndex: nil, name: label ?? "Scenario (line \(scenario.line))")]
        }
        return scenario.steps.enumerated().map { index, step in
            let text = TestNames.stepText(writtenKeyword: step.keywordName, keywordText: step.keywordText, match: step.text, readable: readable)
            let name = TestNames.stepName(for: text, at: index, of: scenario.steps.count, readable: readable)
            let prefix = label.map { $0 + (readable ? TestNames.readableDelimiter : "_") } ?? ""
            return ScenarioCase(scenario: scenario, stepIndex: index, name: prefix + name)
        }
    }

    /// The cases of a scenario, which the generated test takes as its arguments.
    public func casesToRun(_ scenario: GherkinScenario) -> [ScenarioCase] {
        cases(of: scenario, label: nil)
    }

    /// The cases of the examples of a Scenario Outline that run, as ``shouldRun(_:)`` decides for each.
    public func casesToRun(_ examples: [GherkinExample]) -> [ScenarioCase] {
        examplesToRun(examples).flatMap { cases(of: $0.scenario, label: $0.testDescription) }
    }
}
