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

    func testSuiteStarted(at _: Date) { /* Not recorded. */ }
    func testSuiteFinished(at _: Date) { /* Not recorded. */ }
    func didStart(feature _: Feature, at _: Date) { /* Not recorded: BeforeFeature is. */ }
    func didStart(scenario _: Scenario, at _: Date) { /* Not recorded. */ }
    func didStart(step _: Step, at _: Date) { /* Not recorded. */ }
    func didFinish(feature: Feature, result _: Reporter.Result, duration _: Measurement<UnitDuration>) {
        events.append("finished \(feature.title)")
    }
    func didFinish(scenario _: Scenario, result _: Reporter.Result, duration _: Measurement<UnitDuration>) { /* Not recorded. */ }
    func didFinish(step _: Step, result _: Reporter.Result, duration _: Measurement<UnitDuration>) { /* Not recorded. */ }
}
