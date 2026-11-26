//
//  GherkinTagsTrait.swift
//  CucumberSwiftTesting
//
// A scenario's Gherkin tags as a Swift Testing trait, and the scopes that `Cucumber.mapTags(_:)` makes from
// them. The generated tests put the trait on each scenario's test, and on each example's of a Scenario
// Outline, so that the scopes wrap one scenario instance: all of its test cases, its hooks and its steps.

import Foundation
import Testing

/// A scenario's Gherkin tags, on the test that the generated code makes for it. The tags are the
/// feature's, then the Rule's, the scenario's and the Examples block's, in that order, each once and
/// with its `@`. A step or a hook reads them from `Test.current?.traits`.
///
/// When `setupSteps()` registers a closure with ``Cucumber/mapTags(_:)``, the trait runs the scenario
/// inside the scopes the closure returns for these tags. Without a closure it does nothing.
public struct GherkinTagsTrait: TestTrait, TestScoping {
    /// Whether a scope has started to run what it wraps.
    private final class Entered: @unchecked Sendable {
        private let lock = NSLock()
        private var stored = false

        var value: Bool {
            lock.lock()
            defer { lock.unlock() }
            return stored
        }

        func set() {
            lock.lock()
            defer { lock.unlock() }
            stored = true
        }
    }

    /// The tags, in Gherkin order, each with its `@`.
    public let tags: [String]
    /// The scenario the generated test runs, so that the scenario ends inside its scopes.
    let scenario: GherkinScenario?

    /// The tags in order, each once and with its `@`.
    static func effective(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        return tags.compactMap { tag in
            let tagged = tag.hasPrefix("@") ? tag : "@" + tag
            return seen.insert(tagged).inserted ? tagged : nil
        }
    }

    init(tags: [String], scenario: GherkinScenario?) {
        self.tags = Self.effective(tags)
        self.scenario = scenario
    }

    /// Wraps the whole test, all its cases at once, and only when `setupSteps()` registered a closure.
    public func scopeProvider(for test: Test, testCase: Test.Case?) -> GherkinTagsTrait? {
        testCase == nil && !test.isSuite && CucumberSettings.tagMapping != nil ? self : nil
    }

    public func provideScope(for test: Test, testCase _: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        // `setupSteps()` registers the closure, so it runs first, as it does for the first scenario.
        await MainActor.run { Cucumber.shared.loadStepDefinitions() }
        guard let mapping = CucumberSettings.tagMapping else {
            try await function()
            return
        }
        let scopes: [any TestScoping]
        do {
            scopes = try mapping(tags)
        } catch {
            try await runFailing(function, because: error)
            return
        }
        try await nest(scopes[...], for: test, around: function)
    }

    /// Runs `function` inside each scope, the first outermost. A scope that throws before it runs what it
    /// wraps fails the scenario at its first step instead, inside the scopes around it.
    private func nest(_ scopes: ArraySlice<any TestScoping>, for test: Test, around function: @Sendable () async throws -> Void) async throws {
        guard let scope = scopes.first else {
            try await runAndEndScenario(function)
            return
        }
        let entered = Entered()
        do {
            try await scope.provideScope(for: test, testCase: nil) {
                entered.set()
                try await nest(scopes.dropFirst(), for: test, around: function)
            }
        } catch where !entered.value {
            try await runFailing(function, because: error)
        }
    }

    /// Runs the scenario with its steps skipped, and its first step failed with `error`.
    private func runFailing(_ function: @Sendable () async throws -> Void, because error: any Error) async throws {
        let message = "A scope for the tags \(tags.joined(separator: " ")) failed: "
            + ((error as? any LocalizedError)?.errorDescription ?? String(describing: error))
        try await ScenarioContext.$scopeFailure.withValue(message) {
            try await runAndEndScenario(function)
        }
    }

    /// Runs `function`, then ends the scenario inside the scopes, also when `function` throws.
    private func runAndEndScenario(_ function: @Sendable () async throws -> Void) async throws {
        do {
            try await function()
        } catch {
            await endScenario()
            throw error
        }
        await endScenario()
    }

    /// Ends the scenario inside the scopes, if its last case didn't, such as when only some of its steps' tests ran.
    private func endScenario() async {
        if let scenario {
            await Cucumber.shared.endIfStarted(scenario)
        }
    }
}

extension Trait where Self == GherkinTagsTrait {
    /// The Gherkin tags of a scenario, such as `.gherkinTags(["@fixtures:exampleWorld"])`. A tag without its
    /// `@` gets one, and a tag given twice counts once.
    public static func gherkinTags(_ tags: [String]) -> Self {
        Self(tags: tags, scenario: nil)
    }

    /// The tags of the scenario that the generated test runs.
    public static func gherkinTags(of scenario: GherkinScenario) -> Self {
        Self(tags: scenario.tags, scenario: scenario)
    }
}

extension Cucumber {
    /// Maps a scenario's Gherkin tags to the traits whose scopes the scenario runs in, with the Swift Testing
    /// runner. Call it in `setupSteps()`. For each scenario, and each example of a Scenario Outline, the
    /// runner calls `mapping` once with the scenario's tags, such as `["@fixtures:exampleWorld"]`, and runs
    /// the whole scenario inside the scopes of the traits it returns, the first outermost: the scopes'
    /// setup, then the `BeforeScenario` hooks, the steps, the `AfterScenario` hooks, and the scopes'
    /// clean-up. When `mapping` throws, or a scope throws before the scenario starts, the scenario fails
    /// at its first step and its steps don't run. Calling it again replaces the closure.
    nonisolated public static func mapTags(_ mapping: @escaping @Sendable (_ tags: [String]) throws -> [any TestScoping]) {
        CucumberSettings.tagMapping = mapping
    }
}
