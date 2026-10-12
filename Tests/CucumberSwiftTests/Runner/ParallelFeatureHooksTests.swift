//
//  ParallelFeatureHooksTests.swift
//  CucumberSwiftTests
//
//  In a parallel run, a feature's scenarios run in whatever worker and order Xcode chooses, so
//  `AfterFeature` runs once a worker has run all of its tests, or with whole features, after the feature
//  class's last test (#387). These tests run the hooks as the step tests would, without running steps.
//

import Foundation
import XCTest
@testable import CucumberSwift

/// The feature hooks that ran and the features the reporters were told finished, in order.
private final class FeatureHookLog: CucumberTestObserver {
    var events = [String]()

    func testSuiteStarted(at: Date) { /* Not recorded. */ }
    func testSuiteFinished(at: Date) { /* Not recorded. */ }
    func didStart(feature: Feature, at date: Date) { /* Not recorded: BeforeFeature is. */ }
    func didStart(scenario: Scenario, at date: Date) { /* Not recorded. */ }
    func didStart(step: Step, at date: Date) { /* Not recorded. */ }
    func didFinish(feature: Feature, result: Reporter.Result, duration: Measurement<UnitDuration>) {
        events.append("finished \(feature.title)")
    }
    func didFinish(scenario: Scenario, result: Reporter.Result, duration: Measurement<UnitDuration>) { /* Not recorded. */ }
    func didFinish(step: Step, result: Reporter.Result, duration: Measurement<UnitDuration>) { /* Not recorded. */ }
}

class ParallelFeatureHooksTests: XCTestCase {
    private static func reset() {
        Cucumber.parallelTesting = nil
        Cucumber.parallelTestingUnit = nil
        Cucumber.shared.reset()
        CucumberTest.resetSetUp()
    }

    override func setUpWithError() throws {
        Self.reset()
        addTeardownBlock { Self.reset() }
    }

    /// Parses two features, the first with two scenarios of the same title, and returns their titles.
    private func parseFeatures() -> (first: String, second: String) {
        let first = "Parallel \(UUID().uuidString)"
        let second = "Parallel \(UUID().uuidString)"
        Cucumber.shared.parseIntoFeatures("""
        Feature: \(first)
           Scenario: Pay by card
             Given a cart
             When I pay by card
           Scenario: Pay with a gift card
             Given a cart
           Scenario: Pay by card
             Given a cart
        """)
        Cucumber.shared.parseIntoFeatures("""
        Feature: \(second)
           Scenario: Sign in
             Given a cart
        """)
        CucumberTest.featuresLoaded = true
        return (first, second)
    }

    /// Records each feature hook and each feature the reporters are told finished, in order.
    @MainActor
    private func recordFeatureHooks() -> FeatureHookLog {
        let log = FeatureHookLog()
        BeforeFeature { log.events.append("before \($0.title)") }
        AfterFeature { log.events.append("after \($0.title)") }
        let reporters = Cucumber.shared.reporters
        Cucumber.shared.reporters.append(log)
        addTeardownBlock { Cucumber.shared.reporters = reporters }
        return log
    }

    private func steps(of title: String) -> [Step] {
        Cucumber.shared.features.first { $0.title == title }?.scenarios.flatMap(\.steps) ?? []
    }

    /// Runs the step's hooks as its test would, without running the step.
    @MainActor
    private func runHooks(of step: Step) {
        Cucumber.shared.setupBeforeHooksFor(step)
        Cucumber.shared.setupAfterHooksFor(step)
    }

    // A worker can run the feature file's last scenario first, so AfterFeature waits until the worker has
    // run all of its tests, and then runs once for each feature it started, in the order it started them.
    @MainActor
    func testWithScenariosAfterFeatureRunsOnceForEachStartedFeatureWhenTheWorkerFinishes() {
        let (first, second) = parseFeatures()
        let log = recordFeatureHooks()
        Cucumber.parallelTesting = true
        ParallelTesting.makeScenarioClasses()

        steps(of: first).reversed().forEach(runHooks)
        steps(of: second).forEach(runHooks)
        XCTAssertEqual(log.events, ["before \(first)", "before \(second)"])

        Cucumber.shared.finishStartedFeatures()
        Cucumber.shared.finishStartedFeatures()

        let expected = ["before \(first)", "before \(second)", "after \(first)", "finished \(first)", "after \(second)", "finished \(second)"]
        XCTAssertEqual(log.events, expected)
    }

    @MainActor
    func testWithScenariosAFeatureThisWorkerDidNotStartDoesNotFinish() {
        let (first, second) = parseFeatures()
        let log = recordFeatureHooks()
        Cucumber.parallelTesting = true
        ParallelTesting.makeScenarioClasses()

        steps(of: second).forEach(runHooks)
        Cucumber.shared.finishStartedFeatures()

        XCTAssertFalse(log.events.contains { $0.hasSuffix(first) }, "\(log.events)")
        XCTAssertEqual(log.events.filter { $0.hasSuffix(second) }.count, 3, "\(log.events)")
    }

    // A whole feature runs in one worker, so AfterFeature runs in its class's last test, where a failure
    // fails that test, and not again when the worker finishes.
    @MainActor
    func testWithWholeFeaturesAfterFeatureRunsAfterTheFeatureClasssLastTest() {
        let (first, _) = parseFeatures()
        let log = recordFeatureHooks()
        Cucumber.parallelTesting = true
        Cucumber.parallelTestingUnit = .feature
        ParallelTesting.makeScenarioClasses()
        let steps = steps(of: first)

        steps.dropLast().forEach(runHooks)
        XCTAssertEqual(log.events, ["before \(first)"])
        steps.last.map(runHooks)
        XCTAssertEqual(log.events, ["before \(first)", "after \(first)", "finished \(first)"])

        Cucumber.shared.finishStartedFeatures()

        XCTAssertEqual(log.events, ["before \(first)", "after \(first)", "finished \(first)"])
    }

    // When the feature class's last test doesn't run, such as when Xcode is told to run only some tests,
    // the feature finishes with the worker.
    @MainActor
    func testWithWholeFeaturesAFeatureWhoseLastTestDidNotRunFinishesWithTheWorker() {
        let (first, _) = parseFeatures()
        let log = recordFeatureHooks()
        Cucumber.parallelTesting = true
        Cucumber.parallelTestingUnit = .feature
        ParallelTesting.makeScenarioClasses()

        steps(of: first).dropLast().forEach(runHooks)
        Cucumber.shared.finishStartedFeatures()

        XCTAssertEqual(log.events, ["before \(first)", "after \(first)", "finished \(first)"])
    }

    // The duration reported for a feature runs from when this worker started it, not from when the feature
    // file was parsed, which is what `startDate` held before.
    @MainActor
    func testAFeatureStartsWhenItsFirstStepRuns() throws {
        let (first, _) = parseFeatures()
        let feature = try XCTUnwrap(Cucumber.shared.features.first { $0.title == first })
        feature.startDate = .distantPast
        let before = Date()

        steps(of: first).first.map(runHooks)

        XCTAssertGreaterThanOrEqual(feature.startDate, before)
    }

    // With parallel testing off, a feature finishes after the last step in its feature file, as it always has.
    @MainActor
    func testWithoutParallelTestingAfterFeatureRunsAfterTheFeatureFilesLastStep() {
        let (first, _) = parseFeatures()
        let log = recordFeatureHooks()

        steps(of: first).forEach(runHooks)
        XCTAssertEqual(log.events, ["before \(first)", "after \(first)", "finished \(first)"])

        Cucumber.shared.finishStartedFeatures()

        XCTAssertEqual(log.events, ["before \(first)", "after \(first)", "finished \(first)"])
    }

    // XCTest drops a failure recorded after a worker's last test, so an async hook's error is printed then.
    @MainActor
    func testAnAsyncAfterFeatureThatThrowsWhenTheWorkerFinishesDoesNotFailATest() {
        struct HookError: Error {}
        let (first, _) = parseFeatures()
        var ran = false
        AfterFeature { (_: Feature) async throws in
            ran = true
            throw HookError()
        }
        Cucumber.parallelTesting = true
        ParallelTesting.makeScenarioClasses()
        steps(of: first).forEach(runHooks)

        Cucumber.shared.finishStartedFeatures()

        XCTAssertTrue(ran)
        XCTAssertFalse(AsyncStepRunner.isOutsideTest)
    }

    func testTheMessageForAHookThatThrowsOutsideATestNamesTheHookAndTheFeature() throws {
        struct HookError: LocalizedError {
            var errorDescription: String? { "the server is gone" }
        }
        let feature = try XCTUnwrap(Cucumber(withString: "Feature: Checkout").features.first)

        let message = AsyncStepRunner.outsideTestErrorMessage(HookError(), for: feature, file: "Hooks.swift", line: 12)

        XCTAssertEqual(message, "CucumberSwift: the hook at Hooks.swift:12 threw for the feature 'Checkout' after this "
                       + "worker's last test, so it can't fail a test: the server is gone")
    }
}
