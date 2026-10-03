//
//  ParallelTesting.swift
//  CucumberSwift
//
//  Experimental parallel testing (#31). Xcode's parallel testing hands whole test classes to its
//  workers, and the first worker lists the classes to hand out before XCTest asks any of them for a
//  suite. The class for each scenario is made when CucumberTest builds its suite, too late to be listed,
//  so without this a parallel run drops the scenarios, or runs them all in every worker that is handed
//  CucumberTest or a subclass of it.
//
//  With `Cucumber.experimentalParallelTesting`, each scenario's class is made as soon as XCTest has
//  loaded the test bundle, and answers `defaultTestSuite` with its steps. XCTest then lists it like any
//  other class and hands it to one worker, which runs the scenario's steps in order.
//

import Foundation
import XCTest

/// The work runs on the main actor, as `setupSteps()` must, and as XCTest builds its suites.
@MainActor
enum ParallelTesting {
    /// Whether each scenario's class was made before XCTest asked CucumberTest for its suite, as it is in
    /// a parallel worker. CucumberTest's suite then leaves the scenarios out. Locked rather than isolated,
    /// because `defaultTestSuite`, which XCTest declares nonisolated, reads it.
    nonisolated static let classesMade = Locked(false)

    nonisolated static var scenarioClassesMade: Bool {
        classesMade.snapshot
    }

    #if DEBUG
    nonisolated static func reset() {
        classesMade.withLock { $0 = false }
    }
    #endif

    /// Prepares once XCTest has loaded the test bundle and the main actor is first free. In a parallel
    /// worker that is before XCTest lists the classes to hand out. In a serial run XCTest has already
    /// built every suite by then, and preparing does nothing.
    nonisolated static func prepareWhenLoaded() {
        Task { @MainActor in prepare() }
    }

    static func prepare() {
        guard !CucumberTest.hasBeenBuilt, !scenarioClassesMade, Cucumber.shared is StepImplementation else { return }
        // The flag can be set in setupSteps(), so the features and steps are loaded first.
        CucumberTest.loadFeaturesIfNeeded()
        guard FeatureFlags.isExperimentalParallelTesting,
              !FeatureFlags.isOneTestPerScenario,
              !Cucumber.shared.features.isEmpty else { return }
        makeScenarioClasses()
    }

    /// Makes each scenario's class, whose `defaultTestSuite` is the scenario's steps, so that XCTest can
    /// hand the scenario to a worker of its own. The suite is named after its class, which is unique, not
    /// after the scenario: two scenarios with the same name would otherwise have suites with the same name,
    /// and when two workers run those at once, xcodebuild crashes as it records the results.
    static func makeScenarioClasses() {
        for scenarioSuite in CucumberTest.scenarioSuites() {
            guard let testClass = scenarioSuite.tests.first.map({ type(of: $0) }) else { continue }
            let suite = XCTestSuite(name: NSStringFromClass(testClass))
            scenarioSuite.tests.forEach { suite.addTest($0) }
            let defaultTestSuite: @convention(block) (AnyObject) -> XCTestSuite = { _ in suite }
            class_addMethod(object_getClass(testClass),
                            NSSelectorFromString("defaultTestSuite"),
                            imp_implementationWithBlock(defaultTestSuite),
                            "@@:")
        }
        classesMade.withLock { $0 = true }
    }
}
