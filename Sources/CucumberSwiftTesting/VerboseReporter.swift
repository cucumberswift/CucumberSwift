//
//  VerboseReporter.swift
//  CucumberSwiftTesting
//
// Prints each feature, scenario and step as it runs, with its result and duration, in CucumberSwift's
// words and layout (Reporter/Core/VerboseOutput.swift, shared through a symlink).

import Foundation

/// The runner installs it, and it prints when ``Cucumber/verboseOutput``, the `CUCUMBER_VERBOSE`
/// environment variable (`1` or `true`) or your `StepImplementation`'s `verbose` says so.
final class VerboseReporter: CucumberTestObserver {
    private let output: VerboseOutput

    /// - Parameter isEnabled: Asked before every line, because the setting can change after the reporter
    ///   exists: `setupSteps()` runs after the runner has built its reporters.
    init(isEnabled: @escaping () -> Bool = { true }, write: @escaping (String) -> Void = { print($0); fflush(stdout) }) {
        output = VerboseOutput(isEnabled: isEnabled, write: write)
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
        output.stepStarted(keyword: step.keywordName, match: step.match)
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
