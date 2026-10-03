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

    /// The bundle of each scenario's class: the test bundle. A class made at run time belongs to no image,
    /// so `Bundle(for:)` would give the main bundle, which in a test target hosted in an app is the app.
    /// XCTest groups test classes by their bundle, and xcodebuild crashes on scenarios grouped under the app.
    nonisolated private static let bundles = Locked([ObjectIdentifier: Bundle]())
    nonisolated private static let bundleForClassReplaced = Locked(false)

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
    /// hand the scenario to a worker of its own. The suite is the class's, named after the class, which is
    /// unique, not after the scenario: two scenarios with the same name would otherwise have suites with the
    /// same name, and when two workers run those at once, xcodebuild crashes as it records the results.
    static func makeScenarioClasses() {
        let testBundle = (Cucumber.shared as? StepImplementation)?.bundle
        for scenarioSuite in CucumberTest.scenarioSuites() {
            guard let testClass = scenarioSuite.tests.first.map({ type(of: $0) }) else { continue }
            if let testBundle = testBundle {
                bundles.withLock { $0[ObjectIdentifier(testClass)] = testBundle }
            }
            // A suite for the class, as XCTest makes for a class it finds, so that it names the class and
            // xcodebuild can tell which tests it holds. The class has no methods XCTest would add itself.
            let suite = XCTestSuite(forTestCaseClass: testClass)
            scenarioSuite.tests.forEach { suite.addTest($0) }
            let defaultTestSuite: @convention(block) (AnyObject) -> XCTestSuite = { _ in suite }
            class_addMethod(object_getClass(testClass),
                            NSSelectorFromString("defaultTestSuite"),
                            imp_implementationWithBlock(defaultTestSuite),
                            "@@:")
        }
        replaceBundleForClass()
        classesMade.withLock { $0 = true }
    }

    /// Makes `Bundle(for:)` give the test bundle for each scenario's class, and leaves every other class as it was.
    private static func replaceBundleForClass() {
        let alreadyReplaced = bundleForClassReplaced.withLock { replaced -> Bool in
            defer { replaced = true }
            return replaced
        }
        let selector = NSSelectorFromString("bundleForClass:")
        guard !alreadyReplaced, let method = class_getClassMethod(Bundle.self, selector) else { return }
        typealias BundleForClass = @convention(c) (AnyClass, Selector, AnyClass) -> Bundle
        let original = unsafeBitCast(method_getImplementation(method), to: BundleForClass.self)
        let replacement: @convention(block) (AnyClass, AnyClass) -> Bundle = { bundleClass, testClass in
            bundles.withLock { $0[ObjectIdentifier(testClass)] } ?? original(bundleClass, selector, testClass)
        }
        method_setImplementation(method, imp_implementationWithBlock(replacement))
    }
}
