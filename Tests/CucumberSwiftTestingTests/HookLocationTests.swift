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
        BeforeScenario(file: "Hooks.swift", line: 12) { _ in throw HookFailure() }
        Given("a step") { _, _ in }
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        } matching: { issue in
            issue.sourceLocation?.line == 12 && issue.sourceLocation?._filePath == "Hooks.swift"
        }
    }

    @Test func theHooksTheyHadBeforeFileAndLineStillWorkAsFunctionValues() async {
        let beforeScenario: (UInt?, @escaping @MainActor (Scenario) async throws -> Void) -> Void = BeforeScenario
        let afterScenario: (UInt?, @escaping @MainActor (Scenario) async throws -> Void) -> Void = AfterScenario
        let beforeStep: (UInt?, @escaping @MainActor (Step) async throws -> Void) -> Void = BeforeStep
        let afterStep: (UInt?, @escaping @MainActor (Step) async throws -> Void) -> Void = AfterStep
        beforeScenario(nil) { [self] _ in ran.append("before scenario") }
        afterScenario(nil) { [self] _ in ran.append("after scenario") }
        beforeStep(nil) { [self] _ in ran.append("before step") }
        afterStep(nil) { [self] _ in ran.append("after step") }
        Given("a step") { _, _ in }

        await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        #expect(ran == ["before scenario", "before step", "after step", "after scenario"])
    }

    @Test(arguments: ["BeforeStep", "AfterStep"])
    func aThrowingStepHookFailsItsStepScenarioAndFeatureAsInXCTest(kind: String) async throws {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        Given("a step") { _, _ in }
        if kind == "BeforeStep" {
            BeforeStep { _ in throw HookFailure() }
        } else {
            AfterStep { _ in throw HookFailure() }
        }

        await withKnownIssue {
            try? await runFeature {
                await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
            }
        }
        // The step's result is reported before its AfterStep hooks run, as in XCTest: a BeforeStep failure lands on
        // the step, an AfterStep one on the scenario and the feature.
        #expect(observer.log.contains { $0.hasPrefix("step failed") } == (kind == "BeforeStep"))
        #expect(observer.log.contains("scenario failed A"))
        #expect(observer.log.contains("feature failed F"))
    }

    @Test(arguments: ["BeforeStep", "AfterStep"])
    func aThrowingStepHookSkipsTheLaterSteps(kind: String) async throws {
        Given("a step") { [self] _, _ in ran.append("step") }
        if kind == "BeforeStep" {
            BeforeStep { _ in throw HookFailure() }
        } else {
            AfterStep { _ in throw HookFailure() }
        }
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a step", line: 3), step(.given, "a step", line: 4)]))
        }
        // A BeforeStep failure skips the step; an AfterStep failure runs it once.
        #expect(ran == (kind == "AfterStep" ? ["step"] : []))
    }

    @Test(arguments: ["BeforeScenario", "AfterScenario", "BeforeFeature", "AfterFeature"])
    func aThrowingScenarioOrFeatureHookFailsTheScenarioAndFeatureAsInXCTest(kind: String) async throws {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        Given("a step") { _, _ in }
        switch kind {
            case "BeforeScenario": BeforeScenario { _ in throw HookFailure() }
            case "AfterScenario": AfterScenario { _ in throw HookFailure() }
            case "BeforeFeature": BeforeFeature { _ in throw HookFailure() }
            default: AfterFeature { _ in throw HookFailure() }
        }

        await withKnownIssue {
            try? await runFeature {
                await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
            }
        }
        #expect(observer.log.contains("feature failed F"))
        #expect(observer.log.contains("scenario failed A") == (kind != "AfterFeature"))
        #expect(observer.log.contains("scenario passed A") == (kind == "AfterFeature"))
        // BeforeScenario and BeforeFeature fail the first step; AfterScenario and AfterFeature leave the step as reported.
        #expect(observer.log.contains { $0.hasPrefix("step failed") } == kind.hasPrefix("Before"))
    }

    @Test func aFailingStepDefinitionStillFailsItsScenarioAndFeature() async throws {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        Given("a step") { _, _ in throw HookFailure() }

        await withKnownIssue {
            try? await runFeature {
                await Cucumber.shared.run(self.scenario("A", line: 2, steps: [self.step(.given, "a step", line: 3)]))
            }
        }
        #expect(observer.log.contains("scenario failed A"))
        #expect(observer.log.contains("feature failed F"))
    }
}
