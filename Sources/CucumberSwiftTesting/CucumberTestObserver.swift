//
//  CucumberTestObserver.swift
//  CucumberSwiftTesting
//
// What a custom reporter implements, named and shaped as in CucumberSwift, so that the same observer
// works with both runners: only the `Feature`, `Scenario` and `Step` it receives are the runner's own.

import Foundation

/// Adds your own observers to the runner's, as in CucumberSwift:
///
/// ```swift
/// extension Cucumber: CucumberTestObservable {
///     public var observers: [CucumberTestObserver] { [MyTestObserver()] }
/// }
/// ```
@MainActor public protocol CucumberTestObservable {
    var observers: [CucumberTestObserver] { get }
}

/// Is told what the runner saw: each feature, scenario and step as it starts and finishes, with its
/// result and duration. Add observers with ``CucumberTestObservable``.
///
/// The runner calls them on the main actor, in the order the events happen. A feature starts with its
/// first scenario, and finishes after its last one. The test suite starts before the first scenario and
/// finishes after the last.
@preconcurrency @MainActor public protocol CucumberTestObserver {
    func testSuiteStarted(at: Date)
    func testSuiteFinished(at: Date)
    func didStart(feature: Feature, at date: Date)
    func didStart(scenario: Scenario, at date: Date)
    func didStart(step: Step, at date: Date)

    func didFinish(feature: Feature, result: Reporter.Result, duration: Measurement<UnitDuration>)
    func didFinish(scenario: Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>)
    func didFinish(step: Step, result: Reporter.Result, duration: Measurement<UnitDuration>)
}
