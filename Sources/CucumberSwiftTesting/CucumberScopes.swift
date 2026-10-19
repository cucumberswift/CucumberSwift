//
//  CucumberScopes.swift
//  CucumberSwiftTesting
//
// What tells the runner where a test suite and a feature end. Swift Testing runs each scenario as a test
// of its own and has no hook that fires after a suite's last test, so the tests that
// CucumberSwiftTestingPlugin generates carry traits that wrap the whole suite, and each feature's. They
// use test scoping, which the runner's minimum Swift version, 6.1, has. They are public only so that the
// generated code, which is compiled into your test target, can use them.

import Foundation
import Testing

/// Leaves the generated suite unserialized, so that Swift Testing runs its scenarios at the same time.
public struct CucumberParallelScenariosTrait: SuiteTrait, TestTrait {
    public var isRecursive: Bool { true }
}

/// Tells the runner that the test suite has started and finished, around all of its features.
public struct CucumberSuiteTrait: SuiteTrait, TestScoping {
    public var isRecursive: Bool { false }

    public init() {}

    /// Wraps the suite once, not each test case in it.
    public func scopeProvider(for test: Test, testCase: Test.Case?) -> CucumberSuiteTrait? {
        testCase == nil && test.isSuite ? self : nil
    }

    public func provideScope(for _: Test, testCase _: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        await Cucumber.shared.beginSuite()
        do {
            try await function()
        } catch {
            await Cucumber.shared.endSuite()
            throw error
        }
        await Cucumber.shared.endSuite()
    }
}

/// Tells the runner that a feature has finished, after the last of its scenarios.
public struct CucumberFeatureTrait: SuiteTrait, TestScoping {
    let file: String
    let title: String
    let line: Int

    public var isRecursive: Bool { false }

    public init(file: String, title: String, line: Int) {
        self.file = file
        self.title = title
        self.line = line
    }

    public func scopeProvider(for test: Test, testCase: Test.Case?) -> CucumberFeatureTrait? {
        testCase == nil && test.isSuite ? self : nil
    }

    public func provideScope(for _: Test, testCase _: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        do {
            try await function()
        } catch {
            await Cucumber.shared.endFeature(file: file, title: title, line: line)
            throw error
        }
        await Cucumber.shared.endFeature(file: file, title: title, line: line)
    }
}

extension Trait where Self == CucumberSuiteTrait {
    /// Reports the test suite's start and finish to the runner's observers.
    public static var observedByCucumber: Self { Self() }
}

extension Trait where Self == CucumberFeatureTrait {
    /// Reports a feature's finish to the runner's observers, after its last scenario.
    public static func cucumberFeature(file: String, title: String, line: Int) -> Self {
        Self(file: file, title: title, line: line)
    }
}

/// The trait that the generated suite has: serialized, so that scenarios run one at a time in the order of
/// the feature files, unless scenarios run in parallel, which `CUCUMBER_PARALLEL_TESTING` says, and
/// failing that `compiled`, whether the test target defines that compilation condition. Swift Testing
/// asks when it discovers the tests.
public func cucumberScenarioOrder(compiled: Bool) -> any SuiteTrait {
    scenarioOrder(compiled: compiled, environment: ProcessInfo.processInfo.environment)
}

func scenarioOrder(compiled: Bool, environment: [String: String]) -> any SuiteTrait {
    let parallel = parallelAtDiscovery(compiled: compiled, environment: environment)
    CucumberSettings.isSuiteSerialized = !parallel
    return parallel ? CucumberParallelScenariosTrait() : ParallelizationTrait.serialized
}

/// The trait that each feature's suite has: serialized, so that its scenarios run one at a time in the order
/// of the feature file while features run at the same time, when scenarios run in parallel and
/// `Cucumber.parallelTestingUnit` is `.feature`. Otherwise it does nothing.
public func cucumberFeatureOrder(compiled: Bool) -> any SuiteTrait {
    featureOrder(compiled: compiled, environment: ProcessInfo.processInfo.environment)
}

func featureOrder(compiled: Bool, environment: [String: String]) -> any SuiteTrait {
    let parallel = parallelAtDiscovery(compiled: compiled, environment: environment)
    let unit = CucumberSettings.parallelTestingUnit(environment: environment)
    return parallel && unit == .feature ? ParallelizationTrait.serialized : CucumberParallelScenariosTrait()
}

private func parallelAtDiscovery(compiled: Bool, environment: [String: String]) -> Bool {
    // `Cucumber.parallelTesting` and `Cucumber.parallelTestingUnit` are set in `setupSteps()`, so run it
    // now, as the runner would for the first scenario. It needs the main actor, which the tests are
    // discovered on, except in a host that discovers them elsewhere: then the static variables are too
    // late, and the first scenario says so.
    if pthread_main_np() == 1 {
        MainActor.assumeIsolated { Cucumber.shared.loadStepDefinitions() }
    }
    return CucumberSettings.runsInParallel(compiled: compiled, environment: environment)
}
