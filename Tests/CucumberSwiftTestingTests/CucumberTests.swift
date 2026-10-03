@testable import CucumberSwiftTesting
import Foundation
import Testing

/// The runner, one scenario at a time, with step definitions each test registers itself.
@MainActor
@Suite(.serialized)
final class CucumberTests {
    var ran = [String]()

    init() {
        let cucumber = Cucumber.shared
        cucumber.definitions = []
        cucumber.beforeScenarioHooks = []
        cucumber.afterScenarioHooks = []
        cucumber.beforeStepHooks = []
        cucumber.afterStepHooks = []
    }

    func step(_ keyword: Step.Keyword, _ text: String, line: Int) -> GherkinStep {
        GherkinStep(keyword: keyword, keywordName: "Given", text: text, line: line, column: 5, suggestion: "Given(\"\(text)\") { _, _ in }")
    }

    func scenario(_ steps: [GherkinStep]) -> GherkinScenario {
        GherkinScenario(
            featureTitle: "F",
            featureTags: ["f"],
            title: "S",
            tags: ["f", "s"],
            file: "/Features/Test.feature",
            line: 2,
            column: 3,
            steps: steps)
    }

    @Test func stepsRunInOrderAndAndStepsMatchTheKeywordTheyContinue() async {
        Given("a {int}") { [self] match, _ in ran.append("given \(try match.first(\.int))") }
        When("an event") { [self] _, step in ran.append("when \(step.match)") }
        And("more") { [self] _, step in ran.append("and \(step.scenario?.title ?? "")") }
        MatchAll("anything") { [self] _, _ in ran.append("any") }

        await Cucumber.shared.run(scenario([
            step(.given, "a 1", line: 3),
            step([.and, .given], "a 2", line: 4),
            step(.when, "an event", line: 5),
            step([.and, .when], "more", line: 6),
            step(.then, "anything", line: 7)
        ]))
        #expect(ran == ["given 1", "given 2", "when an event", "and S", "any"])
    }

    @Test func aStepNoStepDefinitionMatchesFailsAtItsLineAndTheScenarioStops() async {
        AfterScenario { [self] _ in ran.append("after") }
        Then("a result") { [self] _, _ in ran.append("then") }

        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "something new", line: 3), step(.then, "a result", line: 4)]))
        } matching: { issue in
            issue.sourceLocation?.fileID == "Features/Test.feature" && issue.sourceLocation?.line == 3
                && issue.comments.contains { $0.rawValue.hasPrefix("No CucumberSwift expression found that matches this step.") }
                && issue.comments.contains { $0.rawValue.hasSuffix("Given(\"something new\") { _, _ in }") }
        }
        #expect(ran == ["after"])
    }

    @Test func aStepTwoStepDefinitionsMatchFailsAndNeitherRuns() async {
        Given("a {int}") { [self] _, _ in ran.append("first") }
        MatchAll("a 1") { [self] _, _ in ran.append("second") }

        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a 1", line: 3)]))
        } matching: { issue in
            issue.sourceLocation?.line == 3
                && issue.comments.contains { $0.rawValue.hasPrefix("Ambiguous step 'Given a 1': it matches 2 step definitions, at CucumberTests.swift:") }
        }
        #expect(ran.isEmpty)
    }

    @Test func aThrowingStepFailsAtItsLineAndTheAfterHooksStillRun() async {
        struct Failure: Error {}
        BeforeStep { [self] step in ran.append("before \(step.match)") }
        AfterStep { [self] step in ran.append("after \(step.match)") }
        Given("a failure") { _, _ in throw Failure() }
        Then("a result") { [self] _, _ in ran.append("then") }

        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a failure", line: 3), step(.then, "a result", line: 4)]))
        } matching: { issue in
            issue.sourceLocation?.line == 3 && issue.error is Failure
        }
        #expect(ran == ["before a failure", "after a failure"])
    }

    @Test func aRegexLiteralMatchesAStepsWholeText() async {
        guard #available(macOS 13.0, *) else { return }
        Given(#/I have (\d+) cukes/#) { [self] match, _ in ran.append(String(match.1)) }

        await Cucumber.shared.run(scenario([step(.given, "I have 3 cukes", line: 3)]))
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "I have 3 cukes now", line: 4)]))
        }
        #expect(ran == ["3"])
    }

    @Test func hooksRunByPriorityThenInTheOrderTheyWereAdded() async {
        BeforeScenario { [self] _ in ran.append("none 1") }
        BeforeScenario(priority: 2) { [self] _ in ran.append("2") }
        BeforeScenario { [self] _ in ran.append("none 2") }
        BeforeScenario(priority: 1) { [self] _ in ran.append("1") }

        await Cucumber.shared.run(scenario([]))
        #expect(ran == ["1", "2", "none 1", "none 2"])
    }

    @Test func aStepDefinitionSeesTheStepsDocStringDataTableAndTags() async {
        Given("a document") { [self] _, step in
            ran = [step.docString?.literal ?? "", step.dataTable?.rows.first?.first ?? ""] + step.tags
        }
        let step = GherkinStep(
            keyword: .given,
            keywordName: "Given",
            text: "a document",
            line: 3,
            column: 5,
            docString: DocString(literal: "text", rawLiteral: "  text", contentType: nil),
            dataTable: [["cell"]],
            suggestion: "")
        await Cucumber.shared.run(scenario([step]))
        #expect(ran == ["text", "cell", "f", "s"])
    }
}

// Within this package, the conformance needs no `@retroactive`.
extension Cucumber: StepImplementation {
    public func setupSteps() {}
}
