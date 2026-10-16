//
//  VerboseReporter.swift
//  CucumberSwift
//
//  Copyright © 2026 Tyler Thompson. All rights reserved.
//

import Foundation

/// Prints each feature, scenario and step as it runs, with its result and duration.
///
/// CucumberSwift installs it when the `CUCUMBER_VERBOSE` environment variable is `1` or `true`, or
/// when your `StepImplementation` returns `true` from `verbose`.
final class VerboseReporter: CucumberTestObserver {
    static let environmentKey = VerboseOutput.environmentKey

    private let output: VerboseOutput

    /// - Parameter isEnabled: Asked before every line, because the setting can change after the
    ///   reporter exists: `setupSteps()` runs after CucumberSwift has built its reporters.
    init(isEnabled: @escaping () -> Bool = { true }, write: @escaping (String) -> Void = { print($0); fflush(stdout) }) {
        output = VerboseOutput(isEnabled: isEnabled, write: write)
    }

    /// Whether the environment asks for verbose output.
    static func isEnabled(in environment: [String: String]) -> Bool {
        VerboseOutput.isEnabled(in: environment)
    }

    func testSuiteStarted(at _: Date) { output.suiteStarted() }
    func testSuiteFinished(at _: Date) { output.suiteFinished() }

    func didStart(feature: Feature, at _: Date) {
        output.featureStarted(title: feature.title)
    }

    func didStart(scenario: Scenario, at _: Date) {
        output.scenarioStarted(title: scenario.title)
    }

    func didStart(step: Step, at _: Date) {
        output.stepStarted(keyword: step.writtenKeyword, match: step.match)
    }

    func didFinish(feature: Feature, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        output.featureFinished(title: feature.title, result: result, duration: duration)
    }

    func didFinish(scenario: Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        output.scenarioFinished(title: scenario.title, result: result, duration: duration)
    }

    func didFinish(step _: Step, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        output.stepFinished(result: result, duration: duration)
    }
}
