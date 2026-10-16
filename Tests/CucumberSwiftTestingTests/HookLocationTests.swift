@testable import CucumberSwiftTesting
import Foundation
import Testing

private struct HookFailure: Error {}

// A hook that throws fails at the line where it is written, as with CucumberSwift.
extension CucumberTests {
    /// Runs a feature of one scenario with one step, and expects exactly one issue, at `line` of this file.
    func expectIssue(at line: Int, sourceLocation: Testing.SourceLocation = #_sourceLocation) async throws {
        Given("a step") { _, _ in }
        try await withKnownIssue(sourceLocation: sourceLocation) {
            try await runFeature {
                await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
            }
        } matching: { issue in
            issue.sourceLocation?.line == line && issue.sourceLocation?._filePath == #filePath
        }
    }

    @Test func aThrowingBeforeFeatureHookFailsAtItsOwnLine() async throws {
        let line = #line + 1
        BeforeFeature { _ in throw HookFailure() }
        try await expectIssue(at: line)
    }

    @Test func aThrowingAfterFeatureHookFailsAtItsOwnLine() async throws {
        let line = #line + 1
        AfterFeature { _ in throw HookFailure() }
        try await expectIssue(at: line)
    }

    @Test func aThrowingBeforeScenarioHookFailsAtItsOwnLine() async throws {
        let line = #line + 1
        BeforeScenario { _ in throw HookFailure() }
        try await expectIssue(at: line)
    }

    @Test func aThrowingAfterScenarioHookFailsAtItsOwnLine() async throws {
        let line = #line + 1
        AfterScenario { _ in throw HookFailure() }
        try await expectIssue(at: line)
    }

    @Test func aThrowingBeforeStepHookFailsAtItsOwnLine() async throws {
        let line = #line + 1
        BeforeStep { _ in throw HookFailure() }
        try await expectIssue(at: line)
    }

    @Test func aThrowingAfterStepHookFailsAtItsOwnLine() async throws {
        let line = #line + 1
        AfterStep { _ in throw HookFailure() }
        try await expectIssue(at: line)
    }

    @Test func aHookCanNameWhereItIsWritten() async throws {
        BeforeScenario(file: "/Sources/Hooks.swift", line: 12) { _ in throw HookFailure() }
        Given("a step") { _, _ in }
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        } matching: { issue in
            issue.sourceLocation?.line == 12 && issue.sourceLocation?._filePath == "/Sources/Hooks.swift"
        }
    }
}
