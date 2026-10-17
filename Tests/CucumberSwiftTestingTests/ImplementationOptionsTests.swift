//
//  ImplementationOptionsTests.swift
//  CucumberSwiftTestingTests
//
// The `StepImplementation` properties and `ExecuteFirstStep`, as CucumberSwift has them.

@testable import CucumberSwiftTesting
import Foundation
import Testing

extension CucumberTests {
    // MARK: shouldRunWith

    @Test func shouldRunWithLeavesAScenarioOutWithoutRunningAnyOfItOrTellingAnObserver() async {
        let observer = RecordingObserver()
        Cucumber.shared.reporters = [observer]
        ImplementationSettings.shouldRunWith = { _, tags in tags.contains("s") == false }
        Given("a step") { [self] _, _ in ran.append("given") }
        BeforeScenario { [self] _ in ran.append("before") }

        await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        #expect(ran.isEmpty)
        #expect(observer.log.isEmpty)
    }

    @Test func shouldRunWithIsAskedWithTheScenarioAndItsTagsAfterSetupSteps() async {
        var asked = [String]()
        ImplementationSettings.shouldRunWith = { scenario, tags in
            asked.append("\(scenario?.title ?? "none") \(tags.joined(separator: ","))")
            return true
        }
        Given("a step") { [self] _, _ in ran.append("given") }

        await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        #expect(asked == ["S f,s"])
        #expect(ran == ["given"])
    }

    @Test func shouldRunIsAskedOnceAndSetsUpTheStepDefinitionsFirst() async {
        var asked = 0
        ImplementationSettings.shouldRunWith = { _, _ in
            asked += 1
            return true
        }
        let gherkinScenario = scenario([step(.given, "a step", line: 3)])
        Given("a step") { [self] _, _ in ran.append("given") }
        #expect(Cucumber.shared.shouldRun(gherkinScenario))
        // The test the plugin generates asks first; running it doesn't ask again.
        await Cucumber.shared.run(gherkinScenario)
        #expect(asked == 1)
        #expect(ran == ["given"])
    }

    @Test func shouldRunIsFalseForAScenarioShouldRunWithLeavesOut() {
        ImplementationSettings.shouldRunWith = { _, tags in !tags.contains("s") }
        #expect(!Cucumber.shared.shouldRun(scenario([])))
    }

    @Test func shouldRunFollowsCucumberTagsWhenItIsSet() {
        ImplementationSettings.shouldRunWith = { _, _ in false }
        Cucumber.shared.environment = ["CUCUMBER_TAGS": "s"]
        #expect(Cucumber.shared.shouldRun(scenario([])))
        Cucumber.shared.environment = ["CUCUMBER_TAGS": "other"]
        #expect(!Cucumber.shared.shouldRun(scenario([])))
    }

    @Test func cucumberTagsTakesOverFromShouldRunWith() async {
        Cucumber.shared.environment = ["CUCUMBER_TAGS": "s"]
        ImplementationSettings.shouldRunWith = { _, _ in false }
        Given("a step") { [self] _, _ in ran.append("given") }

        await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        #expect(ran == ["given"])
    }

    // MARK: reverseOrderForAfterHooks

    @Test func afterHooksRunInTheOrderOfBeforeHooksByDefaultAndReversedOnRequest() async {
        func register() {
            AfterScenario { [self] _ in ran.append("scenario 1") }
            AfterScenario(priority: 1) { [self] _ in ran.append("scenario p1") }
            AfterScenario { [self] _ in ran.append("scenario 2") }
            AfterStep { [self] _ in ran.append("step 1") }
            AfterStep(priority: 1) { [self] _ in ran.append("step p1") }
            AfterStep { [self] _ in ran.append("step 2") }
        }
        register()
        Given("a step") { _, _ in }
        await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        #expect(ran == ["step p1", "step 1", "step 2", "scenario p1", "scenario 1", "scenario 2"])

        ran = []
        ImplementationSettings.reverseOrderForAfterHooks = true
        await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        #expect(ran == ["step 2", "step 1", "step p1", "scenario 2", "scenario 1", "scenario p1"])
    }

    @Test func beforeHooksKeepTheirOrderWhenAfterHooksAreReversed() async {
        ImplementationSettings.reverseOrderForAfterHooks = true
        BeforeScenario { [self] _ in ran.append("1") }
        BeforeScenario { [self] _ in ran.append("2") }
        await Cucumber.shared.run(scenario([]))
        #expect(ran == ["1", "2"])
    }

    // MARK: asyncStepTimeout

    @Test func aStepThatOutlastsTheTimeoutFailsAtItsLineAndTheRestOfTheScenarioIsSkipped() async {
        ImplementationSettings.asyncStepTimeout = 0.05
        AfterScenario { [self] _ in ran.append("after") }
        Given("a slow step") { [self] _, _ in
            try await Task.sleep(nanoseconds: 5_000_000_000)
            ran.append("slow finished")
        }
        Then("a result") { [self] _, _ in ran.append("then") }

        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a slow step", line: 3), step(.then, "a result", line: 4)]))
        } matching: { issue in
            issue.sourceLocation?.line == 3 && (issue.error as? StepTimeoutError)?.timeout == 0.05
        }
        // The step was cancelled when the timeout passed, so it didn't finish.
        #expect(ran == ["after"])
        #expect(StepTimeoutError(timeout: 0.05).errorDescription
            == "The async step did not finish within 0.05 seconds. Set `asyncStepTimeout` in your StepImplementation to allow longer.")
    }

    @Test func aSynchronousStepThatBlocksPastTheTimeoutPassesAsInCucumberSwift() async {
        ImplementationSettings.asyncStepTimeout = 0.05
        Given("a blocking step") { [self] _, _ in
            Thread.sleep(forTimeInterval: 0.15)
            ran.append("given")
        }
        await Cucumber.shared.run(scenario([step(.given, "a blocking step", line: 3)]))
        #expect(ran == ["given"])
    }

    @Test func examplesToRunLeavesOutTheExamplesShouldRunWithLeavesOut() {
        ImplementationSettings.shouldRunWith = { _, tags in !tags.contains("left-out") }
        func example(_ line: Int, tags: [String]) -> GherkinExample {
            var scenario = scenario([])
            scenario = GherkinScenario(
                featureTitle: scenario.featureTitle,
                featureTags: [],
                title: "S",
                tags: tags,
                file: scenario.file,
                line: line,
                column: 7,
                steps: [])
            return GherkinExample(scenario)
        }
        let kept = Cucumber.shared.examplesToRun([example(5, tags: []), example(6, tags: ["left-out"]), example(7, tags: ["x"])])
        #expect(kept.map(\.scenario.line) == [5, 7])
    }

    /// Fails at the hook itself, where #421's hooks report a throw.
    @Test func aHookThatOutlastsTheTimeoutFails() async {
        ImplementationSettings.asyncStepTimeout = 0.05
        BeforeScenario { _ in try await Task.sleep(nanoseconds: 5_000_000_000) }
        Given("a step") { [self] _, _ in ran.append("given") }

        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        } matching: { issue in
            issue.sourceLocation?.fileID.hasSuffix("ImplementationOptionsTests.swift") == true && issue.error is StepTimeoutError
        }
        #expect(ran.isEmpty)
    }

    @Test func aStepThatFinishesInTimeIsNotAffected() async {
        ImplementationSettings.asyncStepTimeout = 5
        Given("a step") { [self] _, _ in
            try await Task.sleep(nanoseconds: 10_000_000)
            ran.append("given")
        }
        await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        #expect(ran == ["given"])
    }

    // MARK: continueTestingAfterFailure

    #if compiler(>=6.2)
    @Test(.reportedInFeatureFiles)
    func aStepThatFailedAnExpectationSkipsTheLaterStepsAndTheAfterHooksStillRun() async {
        AfterScenario { [self] _ in ran.append("after") }
        Given("a step") { [self] _, _ in
            #expect(Bool(false), "deliberately")
            ran.append("given")
        }
        Then("a result") { [self] _, _ in ran.append("then") }

        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a step", line: 3), step(.then, "a result", line: 4)]))
        }
        #expect(ran == ["given", "after"])
    }

    /// The switch for the behaviour above: with it off, the scenario goes on after a failed `#expect`.
    @Test(.reportedInFeatureFiles)
    func theLaterStepsRunWhenTheRunnerDoesNotSkipThemAfterAFailedExpectation() async {
        Cucumber.shared.skipsLaterStepsAfterRecordedIssue = false
        Given("a step") { _, _ in #expect(Bool(false), "deliberately") }
        Then("a result") { [self] _, _ in ran.append("then") }

        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a step", line: 3), step(.then, "a result", line: 4)]))
        }
        #expect(ran == ["then"])
    }

    @Test(.reportedInFeatureFiles)
    func anAsyncStepIsNotCancelledByDefaultWhenItFailsAnExpectation() async {
        Given("a step") { [self] _, _ in
            #expect(Bool(false), "deliberately")
            try await Task.sleep(nanoseconds: 50_000_000)
            ran.append("finished")
        }
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        }
        #expect(ran == ["finished"])
    }

    @Test(.reportedInFeatureFiles)
    func anAsyncStepIsCancelledAtItsFirstFailedExpectationWhenTestingDoesNotContinue() async {
        ImplementationSettings.continueTestingAfterFailure = false
        Given("a step") { [self] _, _ in
            #expect(Bool(false), "deliberately")
            try await Task.sleep(nanoseconds: 5_000_000_000)
            ran.append("finished")
        }
        // Only the failed expectation is news: the cancellation it caused is not.
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a step", line: 3)]))
        } matching: { issue in
            issue.error == nil
        }
        #expect(ran.isEmpty)
    }
    #endif

    // MARK: ExecuteFirstStep

    @Test func executeFirstStepRunsTheMatchingStepDefinitionFromAnotherStep() async {
        Given("a basket") { _, _ in await ExecuteFirstStep(matching: "I add 2 cukes") }
        When("I add {int} cukes") { [self] match, step in
            ran.append("add \(try match.first(\.int)) \(step.match) \(step.scenario?.title ?? "-")")
        }
        await Cucumber.shared.run(scenario([step(.given, "a basket", line: 3)]))
        #expect(ran == ["add 2 I add 2 cukes S"])
    }

    @Test func executeFirstStepWithAKeywordConsidersOnlyThatKeywordsStepDefinitions() async {
        Given("a basket") { _, _ in
            await ExecuteFirstStep(keyword: .given, matching: "I add 2 cukes")
            await ExecuteFirstStep(keyword: .when, matching: "I add 2 cukes")
        }
        When("I add {int} cukes") { [self] _, _ in ran.append("when") }
        Given("I add {int} cukes") { [self] _, _ in ran.append("given") }
        MatchAll("I add 2 cukes today") { _, _ in }
        await Cucumber.shared.run(scenario([step(.given, "a basket", line: 3)]))
        #expect(ran == ["given", "when"])
    }

    @Test func executeFirstStepFailsAtTheCallingStepsLineWhenNothingMatchesOrMoreThanOneDoes() async {
        Given("a basket") { _, _ in
            await ExecuteFirstStep(matching: "nothing matches this")
            await ExecuteFirstStep(matching: "twice")
        }
        When("twice") { _, _ in }
        Then("twice") { _, _ in }
        var messages = [String]()
        await withKnownIssue(isIntermittent: false) {
            await Cucumber.shared.run(scenario([step(.given, "a basket", line: 3)]))
        } matching: { issue in
            messages.append(issue.comments.map(\.rawValue).joined())
            return issue.sourceLocation?.line == 3
        }
        #expect(messages.count == 2)
        #expect(messages.first?.contains("No CucumberSwift expression found that matches step 'nothing matches this'") == true)
        #expect(messages.last?.contains("Ambiguous step 'twice': it matches 2 step definitions") == true)
    }

    @Test func executeFirstStepReportsWhatTheStepDefinitionThrows() async {
        struct Failure: Error {}
        Given("a basket") { [self] _, _ in
            await ExecuteFirstStep(matching: "it throws")
            ran.append("caller goes on")
        }
        When("it throws") { _, _ in throw Failure() }
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a basket", line: 3)]))
        } matching: { issue in
            issue.comments.contains { $0.rawValue.hasPrefix("ExecuteFirstStep threw error") }
        }
        #expect(ran == ["caller goes on"])
    }

    // MARK: Suggested step definitions

    func undefinedStep() -> GherkinStep {
        GherkinStep(
            keyword: .given,
            keywordName: "Given",
            text: "I see 3 messages",
            line: 3,
            column: 5,
            suggestion: "EXPRESSION",
            regexLiteralSuggestion: "REGEX",
            bareSlashRegexLiteralSuggestion: "BARE")
    }

    /// The suggestion in the message of the issue an undefined step records.
    func suggestionReported() async -> String {
        var suggestion = ""
        await withKnownIssue {
            await Cucumber.shared.run(scenario([undefinedStep()]))
        } matching: { issue in
            suggestion = issue.comments.last?.rawValue.components(separatedBy: "\n").last ?? ""
            return true
        }
        return suggestion
    }

    @Test func anUndefinedStepSuggestsACucumberExpressionByDefault() async {
        #expect(await suggestionReported() == "EXPRESSION")
    }

    @Test func generateRegexLiteralsSuggestsARegexLiteralInTheStyleTheImplementationSays() async {
        Cucumber.generateRegexLiterals = true
        #expect(await suggestionReported() == "REGEX")
        ImplementationSettings.regexLiteralStyle = .bareSlash
        #expect(await suggestionReported() == "BARE")
    }

    @Test func theEnvironmentVariableTurnsRegexLiteralsOnAndTheVariableWinsOverIt() async {
        Cucumber.shared.environment = ["CUCUMBER_GENERATE_REGEX_LITERALS": "YES"]
        #expect(await suggestionReported() == "REGEX")
        Cucumber.generateRegexLiterals = false
        #expect(await suggestionReported() == "EXPRESSION")
    }

    @Test(arguments: [
        ("YES", true), (" yes ", true), ("True", true), ("1", true),
        ("NO", false), ("false", false), ("0", false),
        ("maybe", false), ("", false)
    ])
    func theEnvironmentVariableIsReadAsCucumberSwiftsFeatureFlagsReadIt(_ value: String, _ expected: Bool) {
        #expect(CucumberSettings.generatesRegexLiterals(environment: ["CUCUMBER_GENERATE_REGEX_LITERALS": value]) == expected)
    }

    @Test func aStaticValueWinsOverTheEnvironmentVariableInBothDirections() {
        let environment = ["CUCUMBER_GENERATE_REGEX_LITERALS": "YES"]
        Cucumber.generateRegexLiterals = false
        #expect(!CucumberSettings.generatesRegexLiterals(environment: environment))
        Cucumber.generateRegexLiterals = true
        #expect(CucumberSettings.generatesRegexLiterals(environment: [:]))
    }

    @Test func aStepFromOlderGeneratedTestsWithoutRegexSuggestionsKeepsItsExpression() async {
        Cucumber.generateRegexLiterals = true
        var suggestion = ""
        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "I see 3 messages", line: 3)]))
        } matching: { issue in
            suggestion = issue.comments.last?.rawValue ?? ""
            return true
        }
        #expect(suggestion.hasSuffix("Given(\"I see 3 messages\") { _, _ in }"))
    }
}
