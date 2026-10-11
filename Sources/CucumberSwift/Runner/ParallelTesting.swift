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
//  With `Cucumber.parallelTesting`, each scenario's class is made while XCTest loads the test
//  bundle, and answers `defaultTestSuite` with its steps. XCTest then lists it like any
//  other class and hands it to one worker, which runs the scenario's steps in order.
//
//  Where the classes are made, and when (#386)
//
//  - `makeScenarioClasses()` is the one place that makes them. `prepare()` decides whether to, and
//    `prepareWhenLoaded()` is what runs when the bundle loads.
//  - What runs at load is `CucumberStepTest.+load`, in the CucumberSwiftObjC target, because Swift can't
//    run code when an image loads. It asks `CucumberTestSupport.prepareForParallelTesting()`, by class
//    name, as the Objective-C target can't import this module. Every test bundle that links CucumberSwift
//    loads it, so no `NSPrincipalClass` or other setup is needed, and a SwiftPM test target, which can't
//    set one, works the same.
//  - Measured with Xcode 26.2, tracing the time of each call, on the iOS Simulator, Mac Catalyst and macOS,
//    for unit tests with and without a host app and with CucumberSwift linked statically and as a framework:
//    the classes were made on the main thread 0.01 to 0.02 seconds after `+load` ran, and XCTest first
//    asked a class for its suite 0.04 to 1.3 seconds after that. Each scenario ran once. A hosted bundle
//    loads into the app, and was no later than a hostless one. See
//    https://github.com/cucumberswift/CucumberSwift/issues/386 for the measurements.
//  - A bundle loaded off the main thread is the one case that is not early by construction: it prepares
//    once the main actor is free, which can be after XCTest built CucumberTest's suite. CucumberTest
//    then holds every scenario, and `CucumberTest.defaultTestSuite` adds a failing test saying so,
//    instead of leaving a run that quietly runs scenarios twice. `classesMadeTooLate` says when.
//
//  Apple says Xcode hands out whole test classes, one at a time to each destination: "Xcode build will
//  distribute tests to each run destination by class" (WWDC20, "Get your test results faster",
//  https://developer.apple.com/videos/play/wwdc2020/10221/). That is why a scenario needs a class.
//  That a target hosted in an app runs in one worker on the Simulators and Mac Catalyst is Xcode's
//  behaviour, measured and not documented by Apple that we found: plain XCTest classes, with no
//  CucumberSwift, ran in one worker there too, as the fixtures in Tests/ParallelFixtures show. Only on
//  macOS did a hosted target run in parallel.
//
//  What is checked
//
//  `ScenarioRuns` counts the starts of each scenario in a process and fails the test that starts one a
//  second time. Together with `classesMadeTooLate`, that covers the ways a parallel run repeats a
//  scenario. A scenario that did not run is not reported, because a scenario skipped on purpose looks
//  the same from inside a process.
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

    /// Whether parallel testing is on, and yet each scenario's class was not made before XCTest asked
    /// CucumberTest for its suite. XCTest can't hand those scenarios to workers, so CucumberTest's suite
    /// holds them instead, and every worker that builds it runs them all. Read when CucumberTest builds
    /// its suite, once the features are loaded and the flag can be set.
    nonisolated static var classesMadeTooLate: Bool {
        FeatureFlags.isParallelTesting && !FeatureFlags.isOneTestPerScenario && !scenarioClassesMade
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

    /// Prepares at once, while XCTest loads the test bundle, so that each scenario's class exists before
    /// XCTest lists the classes to hand out or builds any suite, in every worker. Waiting until the main
    /// actor was first free raced XCTest: a worker without a host app sometimes built CucumberTest's suite
    /// first, scenarios and all, and ran every scenario a second time (#371).
    ///
    /// A bundle loaded off the main thread prepares once the main actor is free.
    nonisolated static func prepareWhenLoaded() {
        if Thread.isMainThread {
            MainActor.assumeIsolated { prepare() }
        } else {
            Task { @MainActor in prepare() }
        }
    }

    static func prepare() {
        guard !CucumberTest.hasBeenBuilt, !scenarioClassesMade, Cucumber.shared is StepImplementation else { return }
        // The flag can be set in setupSteps(), so the features and steps are loaded first.
        CucumberTest.loadFeaturesIfNeeded()
        guard FeatureFlags.isParallelTesting,
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
