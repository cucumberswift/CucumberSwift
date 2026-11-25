//
//  GherkinTagsTraitTests.swift
//  CucumberSwiftTestingTests
//

@testable import CucumberSwiftTesting
import Foundation
import Testing

/// What a scope set up, which the steps and hooks inside it read.
enum ScopeValue {
    @TaskLocal static var name: String?
}

/// What the scopes did, in order, from any isolation.
final class ScopeLog: @unchecked Sendable {
    private let lock = NSLock()
    private var stored = [String]()

    var entries: [String] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func append(_ entry: String) {
        lock.lock()
        defer { lock.unlock() }
        stored.append(entry)
    }
}

struct ScopeError: Error, CustomStringConvertible {
    var description: String { "no fixtures" }
}

/// A scope that logs its setup and clean-up, and sets ``ScopeValue/name`` inside it.
struct LoggingScope: TestScoping {
    let name: String
    let log: ScopeLog
    var failsInSetup = false

    func provideScope(for _: Test, testCase _: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        log.append("\(name) setup")
        if failsInSetup { throw ScopeError() }
        do {
            try await ScopeValue.$name.withValue(name) { try await function() }
        } catch {
            log.append("\(name) clean-up")
            throw error
        }
        log.append("\(name) clean-up")
    }
}

/// `GherkinTagsTrait` and `Cucumber.mapTags(_:)`: a scenario's tags as scopes around it.
extension CucumberTests {
    private func tagged(_ tags: [String], line: Int = 2, steps: [GherkinStep]) -> GherkinScenario {
        GherkinScenario(
            featureTitle: "F",
            featureTags: ["f"],
            title: "S \(line)",
            tags: tags,
            file: "/Features/Test.feature",
            line: line,
            column: 3,
            steps: steps)
    }

    /// Runs the scenario's test as Swift Testing would: its tags' scope around all of its cases, in order.
    private func runTest(_ scenario: GherkinScenario) async throws {
        let test = try #require(Test.current)
        try await GherkinTagsTrait.gherkinTags(of: scenario).provideScope(for: test, testCase: nil) {
            try await self.runCases(of: scenario)
        }
    }

    private func runCases(of scenario: GherkinScenario) async throws {
        for testCase in Cucumber.shared.casesToRun(scenario) {
            try await Cucumber.shared.run(testCase)
        }
    }

    private func useOneTestPerScenario(_ value: Bool?) {
        Cucumber.oneTestPerScenario = value
    }

    @Test func theTagsAreInGherkinOrderOnceEachWithTheirAt() {
        #expect(GherkinTagsTrait.gherkinTags(["feature", "rule", "outline", "feature", "small"]).tags
                == ["@feature", "@rule", "@outline", "@small"])
        #expect(GherkinTagsTrait.gherkinTags(["@fixtures:exampleWorld", "teams:opsAndDesign"]).tags
                == ["@fixtures:exampleWorld", "@teams:opsAndDesign"])
        #expect(GherkinTagsTrait.gherkinTags(of: scenario([])).tags == ["@f", "@s"])
    }

    @Test func withoutAClosureTheTraitScopesNothing() throws {
        let test = try #require(Test.current)
        #expect(GherkinTagsTrait.gherkinTags(["@a"]).scopeProvider(for: test, testCase: nil) == nil)
        Cucumber.mapTags { _ in [] }
        #expect(GherkinTagsTrait.gherkinTags(["@a"]).scopeProvider(for: test, testCase: nil) != nil)
    }

    @Test(arguments: [false, true])
    func theScopesWrapTheHooksAndStepsAndTheClosureRunsOncePerScenario(oneTestPerScenario: Bool) async throws {
        useOneTestPerScenario(oneTestPerScenario)
        defer { useOneTestPerScenario(nil) }
        let log = ScopeLog()
        Cucumber.mapTags { tags in
            log.append("mapped \(tags.joined(separator: " "))")
            return tags.contains("@fixtures") ? [LoggingScope(name: "outer", log: log), LoggingScope(name: "inner", log: log)] : []
        }
        BeforeScenario { _ in log.append("before scenario in \(ScopeValue.name ?? "no scope")") }
        AfterScenario { _ in log.append("after scenario in \(ScopeValue.name ?? "no scope")") }
        Given("a {int}") { match, _ in log.append("step \(try match.first(\.int)) in \(ScopeValue.name ?? "no scope")") }

        try await runTest(tagged(["f", "fixtures"], steps: [step(.given, "a 1", line: 3), step(.given, "a 2", line: 4)]))
        try await runTest(tagged(["f"], line: 6, steps: [step(.given, "a 3", line: 7)]))

        #expect(log.entries == [
            "mapped @f @fixtures",
            "outer setup", "inner setup",
            "before scenario in inner", "step 1 in inner", "step 2 in inner", "after scenario in inner",
            "inner clean-up", "outer clean-up",
            "mapped @f",
            "before scenario in no scope", "step 3 in no scope", "after scenario in no scope"
        ])
    }

    @Test func everyScopeCleansUpAfterAFailedStep() async throws {
        useOneTestPerScenario(true)
        defer { useOneTestPerScenario(nil) }
        let log = ScopeLog()
        Cucumber.mapTags { _ in [LoggingScope(name: "outer", log: log), LoggingScope(name: "inner", log: log)] }
        AfterScenario { _ in log.append("after scenario") }
        Given("a failure") { _, _ in throw ScopeError() }
        Given("a 2") { _, _ in log.append("later step") }

        try await withKnownIssue {
            try await runTest(tagged(["f"], steps: [step(.given, "a failure", line: 3), step(.given, "a 2", line: 4)]))
        } matching: { issue in
            issue.sourceLocation?.line == 3
        }
        #expect(log.entries == ["outer setup", "inner setup", "after scenario", "inner clean-up", "outer clean-up"])
    }

    @Test func aThrowingClosureFailsOnlyItsScenarioAtItsFirstStep() async throws {
        useOneTestPerScenario(true)
        defer { useOneTestPerScenario(nil) }
        Cucumber.mapTags { tags in
            if tags.contains("@broken") { throw ScopeError() }
            return []
        }
        BeforeScenario { [self] scenario in ran.append("before \(scenario.title)") }
        AfterScenario { [self] scenario in ran.append("after \(scenario.title)") }
        Given("a {int}") { [self] match, _ in ran.append("step \(try match.first(\.int))") }

        try await withKnownIssue {
            try await runTest(tagged(["broken"], steps: [step(.given, "a 1", line: 3)]))
        } matching: { issue in
            issue.sourceLocation?.fileID == "Features/Test.feature" && issue.sourceLocation?.line == 3
                && issue.comments.contains { $0.rawValue == "A scope for the tags @broken failed: no fixtures" }
        }
        try await runTest(tagged(["fine"], line: 6, steps: [step(.given, "a 2", line: 7)]))

        #expect(ran == ["before S 6", "step 2", "after S 6"])
    }

    @Test func aScopeThatThrowsInItsSetupFailsTheScenarioInsideTheScopesAroundIt() async throws {
        useOneTestPerScenario(true)
        defer { useOneTestPerScenario(nil) }
        let log = ScopeLog()
        Cucumber.mapTags { _ in [LoggingScope(name: "outer", log: log), LoggingScope(name: "inner", log: log, failsInSetup: true)] }
        Given("a {int}") { _, _ in log.append("step") }

        try await withKnownIssue {
            try await runTest(tagged(["f"], steps: [step(.given, "a 1", line: 3)]))
        } matching: { issue in
            issue.sourceLocation?.line == 3 && issue.comments.contains { $0.rawValue.hasSuffix("failed: no fixtures") }
        }
        #expect(log.entries == ["outer setup", "inner setup", "outer clean-up"])
    }

    @Test func aScenarioWhoseLastCaseDidntRunEndsInsideItsScopes() async throws {
        useOneTestPerScenario(false)
        defer { useOneTestPerScenario(nil) }
        let log = ScopeLog()
        Cucumber.mapTags { _ in [LoggingScope(name: "fixtures", log: log)] }
        AfterScenario { _ in log.append("after scenario in \(ScopeValue.name ?? "no scope")") }
        Given("a {int}") { _, _ in }
        let scenario = tagged(["f"], steps: [step(.given, "a 1", line: 3), step(.given, "a 2", line: 4)])
        let test = try #require(Test.current)

        // As when Xcode runs only the first step's test.
        try await GherkinTagsTrait.gherkinTags(of: scenario).provideScope(for: test, testCase: nil) {
            try await Cucumber.shared.run(Cucumber.shared.casesToRun(scenario)[0])
        }
        #expect(log.entries == ["fixtures setup", "after scenario in fixtures", "fixtures clean-up"])
    }
}
