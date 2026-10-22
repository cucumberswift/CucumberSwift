@testable import CucumberSwiftTesting
import Foundation
import Testing

/// What the test target's `StepImplementation` says, so that tests can turn its properties on.
@MainActor
enum ImplementationSettings {
    static var verbose = false
    static var shouldRunWith: (Scenario?, [String]) -> Bool = { _, _ in true }
    static var continueTestingAfterFailure = true
    static var reverseOrderForAfterHooks = false
    static var asyncStepTimeout: TimeInterval = 60
    static var regexLiteralStyle = RegexLiteralStyle.extendedDelimiter

    /// What `setupSteps()` sets `Cucumber.parallelTesting` to, if anything.
    static var parallelTesting: Bool?

    static func reset() {
        verbose = false
        parallelTesting = nil
        shouldRunWith = { _, _ in true }
        continueTestingAfterFailure = true
        reverseOrderForAfterHooks = false
        asyncStepTimeout = 60
        regexLiteralStyle = .extendedDelimiter
    }
}

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
        cucumber.beforeFeatureHooks = []
        cucumber.afterFeatureHooks = []
        cucumber.dsl = DSLFeatures()
        // No reporters, so that these tests write no report; the reporting tests add their own.
        cucumber.reporters = []
        cucumber.environment = [:]
        cucumber.resetObservation()
        Cucumber.reportPath = nil
        Cucumber.verboseOutput = false
        ImplementationSettings.reset()
        Cucumber.generateRegexLiterals = nil
        Cucumber.generateMacros = nil
        cucumber.skipsLaterStepsAfterRecordedIssue = true
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

    @Test func aThrowingBeforeStepHookSkipsTheStepButNotItsAfterStepHooks() async {
        struct Failure: Error {}
        let hookLine = #line + 1
        BeforeStep { [self] step in
            ran.append("before \(step.match)")
            throw Failure()
        }
        AfterStep { [self] step in ran.append("after \(step.match)") }
        Given("a step") { [self] _, _ in ran.append("given") }
        Then("a result") { [self] _, _ in ran.append("then") }

        await withKnownIssue {
            await Cucumber.shared.run(scenario([step(.given, "a step", line: 3), step(.then, "a result", line: 4)]))
        } matching: { issue in
            issue.sourceLocation?.line == hookLine && issue.error is Failure
        }
        #expect(ran == ["before a step", "after a step"])
    }

    #if compiler(>=6.2)
    /// `filterIssues` sees the issue after `reportedInFeatureFiles` has moved it, and drops it only if it is
    /// at the step's line with the step as it ran and where it was recorded. Any other issue fails the test.
    @Test(.filterIssues { issue in
        !(issue.sourceLocation?.fileName == "Test.feature" && issue.sourceLocation?.line == 7
            && issue.comments.map(\.rawValue).suffix(2).first == "Given the basket has 4 cukes"
            && issue.comments.contains { $0.rawValue.hasPrefix("Recorded at CucumberTests.swift:") })
    }, .reportedInFeatureFiles)
    func aFailedExpectationInAStepIsReportedAtTheStepsLine() async {
        Given("the basket has {int} cukes") { _, _ in
            #expect(Bool(false), "deliberately")
        }
        await Cucumber.shared.run(scenario([step(.given, "the basket has 4 cukes", line: 7)]))
    }
    #endif

    #if compiler(>=6.2)
    /// Two scenarios that run at the same time, each failing an expectation after the other's step has
    /// started. Each failure is reported at its own scenario's step, with that step as it ran.
    @Test(.filterIssues { issue in
        let comments = issue.comments.map(\.rawValue)
        let expected = [("First.feature", 3, "Given the first fails"), ("Second.feature", 13, "Given the second fails")]
        guard let match = expected.first(where: { issue.sourceLocation?.fileName == $0.0 && issue.sourceLocation?.line == $0.1 }),
              comments.contains(match.2),
              comments.contains(where: { $0.hasPrefix("Recorded at CucumberTests.swift:") }) else { return true }
        OverlapRecord.shared.append(match.2)
        return false
    }, .reportedInFeatureFiles)
    func failuresInOverlappingScenariosAreReportedAtTheirOwnSteps() async {
        OverlapRecord.shared.removeAll()
        var started = [String]()
        var failed = [String]()
        BeforeScenario { [self] scenario in ran.append("before \(scenario.title)") }
        AfterScenario { [self] scenario in ran.append("after \(scenario.title)") }
        Given("the {word} fails") { [self] match, step in
            let name = try match.first(\.word)
            let other = name == "first" ? "second" : "first"
            started.append(name)
            ran.append("\(step.scenario?.title ?? "") step")
            // The first waits until the second's step has started, and the second until the first has
            // failed, so each fails while the other's step is the one that started last.
            await Self.yield(until: { name == "first" ? started.contains(other) : failed.contains(other) }, "the other scenario")
            #expect(Bool(false), "deliberately")
            failed.append(name)
        }
        Then("it stops") { [self] _, step in ran.append("\(step.scenario?.title ?? "") then") }

        func scenario(_ title: String, file: String, line: Int) -> GherkinScenario {
            GherkinScenario(
                featureTitle: "F",
                featureTags: [],
                title: title,
                tags: [],
                file: "/Features/\(file).feature",
                line: line - 1,
                column: 3,
                steps: [step(.given, "the \(title) fails", line: line), step(.then, "it stops", line: line + 1)])
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await Cucumber.shared.run(scenario("first", file: "First", line: 3)) }
            group.addTask { await Cucumber.shared.run(scenario("second", file: "Second", line: 13)) }
        }
        #expect(OverlapRecord.shared.values.sorted() == ["Given the first fails", "Given the second fails"])
        #expect(failed == ["first", "second"])
        // Each scenario's steps run in order, between its own hooks, though the scenarios overlap. A failed
        // `#expect` skips the later steps, as after a failed XCTest assertion.
        for title in ["first", "second"] {
            #expect(ran.filter { $0.hasSuffix(" \(title)") || $0.hasPrefix("\(title) ") }
                == ["before \(title)", "\(title) step", "after \(title)"])
        }
    }
    #endif

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

/// The failures `failuresInOverlappingScenariosAreReportedAtTheirOwnSteps` saw where it expected them.
final class OverlapRecord: @unchecked Sendable {
    static let shared = OverlapRecord()
    private let lock = NSLock()
    private var recorded = [String]()

    var values: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func append(_ value: String) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(value)
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        recorded.removeAll()
    }
}

// Within this package, the conformance needs no `@retroactive`.
extension Cucumber: StepImplementation {
    public var verbose: Bool { ImplementationSettings.verbose }
    public var continueTestingAfterFailure: Bool { ImplementationSettings.continueTestingAfterFailure }
    public var reverseOrderForAfterHooks: Bool { ImplementationSettings.reverseOrderForAfterHooks }
    public var asyncStepTimeout: TimeInterval { ImplementationSettings.asyncStepTimeout }
    public var regexLiteralStyle: RegexLiteralStyle { ImplementationSettings.regexLiteralStyle }
    public func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool { ImplementationSettings.shouldRunWith(scenario, tags) }

    public func setupSteps() {
        if let parallelTesting = ImplementationSettings.parallelTesting { Cucumber.parallelTesting = parallelTesting }
    }
}
