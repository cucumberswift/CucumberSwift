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
//  With `Cucumber.parallelTestingUnit = .feature` (#387), each feature's class is made instead, holding
//  the steps of all its scenarios, so that one worker runs the whole feature. Xcode runs a class's tests
//  sorted by name, and a result bundle names a test by its class and method, so the method names start
//  with the scenario's position and title (`Scenario.methodNamePrefix`).
//
//  Feature hooks (#387): with the classes made, the scenarios run in whatever worker and order Xcode
//  chooses, so `AfterFeature` no longer runs after the feature file's last step. It runs in the teardown
//  of a feature class's last test, or else in `testBundleDidFinish`, once per worker for each feature that
//  worker started (`Cucumber.finishStartedFeatures`). XCTest calls that once in every worker, after its
//  last test, and drops any failure recorded there, so an async hook's error is printed instead.
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
//  Without the setting
//
//  A parallel run without `Cucumber.parallelTesting` is wrong, and can pass (#389). It can't be fixed by
//  turning the mode on, as XCTest only says a process is a parallel worker once the bundle has loaded. So
//  CucumberTest's suite is one failing test that names the setting, in place of the scenarios, and in a
//  worker never handed CucumberTest the first test to start fails: see `ParallelWorkerObserver` in
//  TestObservation.swift.
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

    /// With ``ParallelTestingUnit/feature``, the last step of each feature's class, whose test's teardown
    /// finishes the feature.
    nonisolated private static let featureLastSteps = Locked(Set<ObjectIdentifier>())

    /// Whether a feature ends after its scenarios in this worker rather than after the last step in its
    /// feature file: whether the scenario or feature classes were made, so that the scenarios run in
    /// whatever order and worker Xcode chooses.
    nonisolated static var defersFeatureEnds: Bool {
        scenarioClassesMade
    }

    /// Whether the step is the last test of its feature's class, made with ``ParallelTestingUnit/feature``.
    nonisolated static func isLastStepOfFeatureClass(_ step: Step) -> Bool {
        featureLastSteps.withLock { $0.contains(ObjectIdentifier(step)) }
    }

    #if DEBUG
    nonisolated static func reset() {
        classesMade.withLock { $0 = false }
        featureLastSteps.withLock { $0.removeAll() }
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
    ///
    /// With ``ParallelTestingUnit/feature`` it makes each feature's class instead, whose suite is the steps
    /// of all of the feature's scenarios, so that XCTest hands the whole feature to one worker.
    static func makeScenarioClasses() {
        let testBundle = (Cucumber.shared as? StepImplementation)?.bundle
        let suites: [XCTestSuite]
        if FeatureFlags.parallelTestingUnit == .feature {
            let featureSuites = CucumberTest.featureSuites()
            featureLastSteps.withLock { $0 = Set(featureSuites.map { ObjectIdentifier($0.lastStep) }) }
            suites = featureSuites.map(\.suite)
        } else {
            suites = CucumberTest.scenarioSuites()
        }
        for scenarioSuite in suites {
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

extension CucumberTest {
    /// With ``ParallelTestingUnit/feature``: a suite for each feature with a scenario that will run, holding
    /// the tests of the class made for the feature, one for each step of each such scenario, in the feature
    /// file's order, and the feature's last step among them. Xcode then hands the feature to one worker.
    ///
    /// Xcode runs a class's tests sorted by name, and a result bundle names a test by its class and method,
    /// so each method's name starts with its scenario's zero-padded position and the scenario's title,
    /// then the step's position: `2 › Pay by card › 3 › Then the cart holds 1 items`, or
    /// `Scenario02_PayByCard_Step002_ThenTheCartHolds1Items` without readable test names.
    static func featureSuites() -> [(suite: XCTestSuite, lastStep: Step)] {
        var suites = [(suite: XCTestSuite, lastStep: Step)]()
        var names = Set<String>()
        for feature in Cucumber.shared.features.taggedElements(with: Cucumber.shared.environment, askImplementor: false) {
            let scenarios = feature.scenarios.taggedElements(with: Cucumber.shared.environment, askImplementor: true)
            guard let lastStep = scenarios.last(where: { !$0.steps.isEmpty })?.steps.last else { continue }
            let base = generatedTestName(feature.title)
            var name = base
            var count = 1
            while names.contains(name) {
                count += 1
                name = "\(base) \(count)"
            }
            names.insert(name)
            guard let testCase = TestCaseGenerator.makeClass(className: name, superclass: StepTestCase.superclass) else { continue }
            objc_registerClassPair(testCase)
            let suite = XCTestSuite(name: name)
            var tests = [XCTestCase]()
            for scenario in scenarios {
                let position = feature.scenarios.firstIndex { $0 === scenario } ?? 0
                let prefix = Scenario.methodNamePrefix(for: scenario.title,
                                                       at: position,
                                                       of: feature.scenarios.count,
                                                       readable: FeatureFlags.isReadableTestNames)
                addStepTests(to: testCase, for: scenario, methodNamePrefix: prefix, tests: &tests)
            }
            tests.forEach { suite.addTest($0) }
            suites.append((suite, lastStep))
        }
        return suites
    }
}
