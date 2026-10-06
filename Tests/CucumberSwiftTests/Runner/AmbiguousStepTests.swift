//
//  AmbiguousStepTests.swift
//  CucumberSwiftTests
//
//  Regression coverage for issue #37, diagnosed by @marton78 in #123. When more than one step
//  definition matched a step, the one registered last silently replaced the others, so the step ran
//  code its author may not have meant. As in other Cucumber implementations, such a step is now
//  ambiguous: it fails, runs none of the definitions, and says where each one is.
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import CucumberSwift

class AmbiguousStepTests: XCTestCase {
    private static let featureURI = "file:///Features/Ambiguous.feature"

    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
        CustomReporterTests.mockObserver.reset()
    }

    private var steps: [Step] {
        Cucumber.shared.features.flatMap { $0.scenarios.flatMap { $0.steps } }
    }

    private func parseFeature(withSteps steps: String) {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
        \(steps)
        """, uri: Self.featureURI)
    }

    // The case reported in #37.
    func testTwoDefinitionsWithTheSameKeywordMakeTheStepAmbiguous() throws {
        parseFeature(withSteps: "When the member goes to the messages screen")
        let firstLine = #line + 1
        When("^the member goes to the messages screen$") { _, _ in }
        let secondLine = #line + 1
        When("^the member goes to the messages screen$") { _, _ in }

        let step = try XCTUnwrap(steps.first)
        XCTAssertTrue(step.isAmbiguous)
        XCTAssertEqual(step.matchingDefinitions.map(\.line), [firstLine, secondLine])
    }

    func testDifferentPatternsThatMatchTheSameStepMakeItAmbiguous() throws {
        parseFeature(withSteps: "Given there are 3 flights")
        Given("there are {int} flights") { _, _ in }
        Given("^there are (\\d+) flights$") { _, _ in }

        XCTAssertTrue(try XCTUnwrap(steps.first).isAmbiguous)
    }

    // MatchAll applies to a step whatever its keyword, so it competes with a Given.
    func testGivenAndMatchAllMakeAGivenStepAmbiguous() throws {
        parseFeature(withSteps: "Given some precondition")
        Given("some precondition") { _, _ in }
        MatchAll("some precondition") { _, _ in }

        XCTAssertTrue(try XCTUnwrap(steps.first).isAmbiguous)
    }

    // A When never applies to a Given step, so it does not compete with a Given.
    func testGivenAndWhenDoNotMakeAGivenStepAmbiguous() throws {
        parseFeature(withSteps: "Given some precondition")
        var givenCalled = false
        var whenCalled = false
        Given("some precondition") { _, _ in givenCalled = true }
        When("some precondition") { _, _ in whenCalled = true }

        XCTAssertFalse(try XCTUnwrap(steps.first).isAmbiguous)
        Cucumber.shared.executeFeatures()
        XCTAssertTrue(givenCalled)
        XCTAssertFalse(whenCalled)
    }

    // An And step takes the keyword of the step before it, so a When and an And definition compete for it.
    func testWhenAndAndMakeAnAndStepAfterAWhenAmbiguous() throws {
        parseFeature(withSteps: """
             When some action
               And some other action
        """)
        When("^some (.*)action$") { _, _ in }
        And("some other action") { _, _ in }

        XCTAssertFalse(steps[0].isAmbiguous)
        XCTAssertTrue(steps[1].isAmbiguous)
    }

    func testAStepOneDefinitionMatchesIsNotAmbiguous() throws {
        parseFeature(withSteps: """
             Given some precondition
               And some other precondition
        """)
        Given("some precondition") { _, _ in }
        Given("some other precondition") { _, _ in }

        XCTAssertEqual(steps.map(\.isAmbiguous), [false, false])
        XCTAssertEqual(steps.map(\.matchingDefinitions.count), [1, 1])
    }

    func testAnAmbiguousStepRunsNoneOfItsDefinitionsAndIsReportedAmbiguous() throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("Needs XCTExpectFailure") }
        parseFeature(withSteps: "Given some precondition")
        var firstCalled = false
        var secondCalled = false
        Given("some precondition") { _, _ in firstCalled = true }
        MatchAll("some precondition") { _, _ in secondCalled = true }
        var stepResult: Reporter.Result?
        var scenarioResult: Reporter.Result?
        CustomReporterTests.mockObserver.didFinishStep = { _, result, _ in stepResult = result }
        CustomReporterTests.mockObserver.didFinishScenario = { _, result, _ in scenarioResult = result }

        // The feature's tests are not run by XCTest here, so the failure lands on this test.
        XCTExpectFailure("The step is ambiguous") {
            Cucumber.shared.executeFeatures()
        }

        XCTAssertFalse(firstCalled)
        XCTAssertFalse(secondCalled)
        XCTAssertEqual(try XCTUnwrap(steps.first).result, .ambiguous)
        XCTAssertEqual(stepResult, .ambiguous)
        XCTAssertEqual(scenarioResult, .failed)
    }

    func testTheFailureNamesEveryMatchingDefinitionAtTheStepInTheFeatureFile() throws {
        parseFeature(withSteps: "Given some precondition")
        let firstLine = #line + 1
        Given("some precondition") { _, _ in }
        let secondLine = #line + 1
        MatchAll("^some (.*)$") { _, _ in }
        let step = try XCTUnwrap(steps.first)

        let message = CucumberTest.ambiguousStepMessage(for: step)
        XCTAssertEqual(message, "Ambiguous step 'Given some precondition': it matches 2 step definitions, at AmbiguousStepTests.swift:\(firstLine) and AmbiguousStepTests.swift:\(secondLine). Remove all but one of them, or make their patterns more specific.")

        let issue = CucumberTest.ambiguousStepIssue(for: step)
        XCTAssertEqual(issue.compactDescription, message)
        XCTAssertEqual(issue.sourceCodeContext.location?.fileURL, URL(string: Self.featureURI))
        XCTAssertEqual(issue.sourceCodeContext.location?.lineNumber, 3)
    }

    // The failure names each step with its own feature file's keyword, not the last parsed file's (#290).
    func testTheFailureNamesTheStepInItsFeatureFilesLanguage() throws {
        parseFeature(withSteps: "Given some precondition")
        Cucumber.shared.parseIntoFeatures("""
        # language: es
        Característica: Pepinos
           Escenario: Comer pepinos
             Cuando como 2 pepinos
        """, uri: "file:///Features/Pepinos.feature")
        Given("some precondition") { _, _ in }
        MatchAll("^some (.*)$") { _, _ in }
        When("como {int} pepinos") { _, _ in }
        MatchAll("^como (\\d+) pepinos$") { _, _ in }

        XCTAssertEqual(steps.map(\.isAmbiguous), [true, true])
        let messages = steps.map { CucumberTest.ambiguousStepMessage(for: $0) }
        XCTAssertTrue(messages[0].hasPrefix("Ambiguous step 'Given some precondition': "), messages[0])
        XCTAssertTrue(messages[1].hasPrefix("Ambiguous step 'Cuando como 2 pepinos': "), messages[1])
    }

    // The failure names the step with its keyword as written: Dado or Y, not Spanish's last forms, Dadas and E (#332).
    func testTheFailureNamesTheStepWithItsKeywordAsWritten() throws {
        defer { Scope.language = .default }
        Cucumber.shared.parseIntoFeatures("""
        # language: es
        Característica: Una cesta de pepinos
           Escenario: Llenar la cesta
             Dado tengo 4 pepinos
             Y como 1 pepino
        """)
        MatchAll("^tengo (\\d+) pepinos$") { _, _ in }
        Given("tengo {int} pepinos") { _, _ in }
        MatchAll("^como (\\d+) pepino$") { _, _ in }
        Given("como {int} pepino") { _, _ in }

        XCTAssertEqual(steps.map(\.isAmbiguous), [true, true])
        let messages = steps.map { CucumberTest.ambiguousStepMessage(for: $0) }
        XCTAssertTrue(messages[0].hasPrefix("Ambiguous step 'Dado tengo 4 pepinos': "), messages[0])
        XCTAssertTrue(messages[1].hasPrefix("Ambiguous step 'Y como 1 pepino': "), messages[1])
    }

    func testTheFailureListsThreeDefinitions() throws {
        parseFeature(withSteps: "Given some precondition")
        let firstLine = #line + 1
        Given("some precondition") { _, _ in }
        Given("some {word}") { _, _ in }
        MatchAll("^some (.*)$") { _, _ in }

        let message = CucumberTest.ambiguousStepMessage(for: try XCTUnwrap(steps.first))
        XCTAssertTrue(message.contains("it matches 3 step definitions, at AmbiguousStepTests.swift:"), message)
        XCTAssertEqual(message.components(separatedBy: "AmbiguousStepTests.swift:").count, 4, message)
        XCTAssertTrue(message.contains("\(firstLine), AmbiguousStepTests.swift:\(firstLine + 1) and AmbiguousStepTests.swift:\(firstLine + 2). "), message)
    }

    func testExecuteFirstStepFailsOnAnAmbiguousStepAndRunsNothing() throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("Needs XCTExpectFailure") }
        parseFeature(withSteps: "Given some precondition")
        var calls = 0
        Given("some precondition") { _, _ in calls += 1 }
        MatchAll("some precondition") { _, _ in calls += 1 }

        XCTExpectFailure("The step is ambiguous") {
            ExecuteFirstStep(matching: "some precondition")
        }
        XCTAssertEqual(calls, 0)
    }

    // Ambiguity for ExecuteFirstStep is about the text asked for, not the text of the step it finds.
    func testExecuteFirstStepRunsTheOneDefinitionThatMatchesTheRequestedText() throws {
        parseFeature(withSteps: "Given there are 3 flights")
        var exactCalled = false
        var patternCalled = false
        Given("^there are 3 flights$") { _, _ in exactCalled = true }
        Given("^there are \\d+ flights$") { _, _ in patternCalled = true }
        XCTAssertTrue(try XCTUnwrap(steps.first).isAmbiguous)

        ExecuteFirstStep(matching: "there are 4 flights")

        XCTAssertFalse(exactCalled)
        XCTAssertTrue(patternCalled)
    }

    func testExecuteFirstStepNamesOnlyTheDefinitionsThatMatchTheRequestedText() throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("Needs XCTExpectFailure") }
        parseFeature(withSteps: "Given there are 3 flights")
        Given("^there are 3 flights$") { _, _ in }
        let firstLine = #line + 1
        Given("^there are \\d+ flights$") { _, _ in }
        MatchAll("^there are (\\d+) flights$") { _, _ in }

        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { issue in
            issue.compactDescription.hasSuffix("Ambiguous step 'there are 4 flights': it matches 2 step definitions, at AmbiguousStepTests.swift:\(firstLine) and AmbiguousStepTests.swift:\(firstLine + 1). Remove all but one of them, or make their patterns more specific.")
        }
        XCTExpectFailure("The requested text is ambiguous", options: options) {
            ExecuteFirstStep(matching: "there are 4 flights")
        }
    }

    // A definition attached only to a later step still competes for the requested text.
    func testExecuteFirstStepIsAmbiguousWhenAnotherStepHasTheOtherMatchingDefinition() throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("Needs XCTExpectFailure") }
        parseFeature(withSteps: """
             Given there are 3 flights
               And there are 4 flights
        """)
        var calls = 0
        let firstLine = #line + 1
        Given("^there are \\d+ flights$") { _, _ in calls += 1 }
        Given("^there are 4 flights$") { _, _ in calls += 1 }
        XCTAssertFalse(steps[0].isAmbiguous)

        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { issue in
            issue.compactDescription.hasSuffix("it matches 2 step definitions, at AmbiguousStepTests.swift:\(firstLine) and AmbiguousStepTests.swift:\(firstLine + 1). Remove all but one of them, or make their patterns more specific.")
        }
        XCTExpectFailure("The requested text is ambiguous", options: options) {
            ExecuteFirstStep(matching: "there are 4 flights")
        }
        XCTAssertEqual(calls, 0)
    }

    func testExecuteFirstStepFailsWhenNoDefinitionMatchesTheRequestedText() throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("Needs XCTExpectFailure") }
        parseFeature(withSteps: "Given there are 3 flights")
        var calls = 0
        Given("^there are \\d+ flights$") { _, _ in calls += 1 }

        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { issue in
            issue.compactDescription.hasSuffix("No CucumberSwift expression found that matches step 'there are no flights'")
        }
        XCTExpectFailure("No step definition matches the text", options: options) {
            ExecuteFirstStep(matching: "there are no flights")
        }
        XCTAssertEqual(calls, 0)
    }

    // A definition attached to several steps is still one step definition.
    func testExecuteFirstStepCountsADefinitionOnSeveralStepsOnce() throws {
        parseFeature(withSteps: """
             Given there are 3 flights
               And there are 4 flights
        """)
        var calls = 0
        Given("^there are \\d+ flights$") { _, _ in calls += 1 }

        ExecuteFirstStep(matching: "there are 5 flights")

        XCTAssertEqual(calls, 1)
    }

    func testAnAmbiguousStepIsRecordedAtTheStepOnTheRunningTest() throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("Needs XCTExpectFailure") }
        parseFeature(withSteps: "Given some precondition")
        Given("some precondition") { _, _ in }
        MatchAll("some precondition") { _, _ in }
        let step = try XCTUnwrap(steps.first)

        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { issue in
            issue.compactDescription == CucumberTest.ambiguousStepMessage(for: step)
                && issue.sourceCodeContext.location?.fileURL == URL(string: Self.featureURI)
        }
        XCTExpectFailure("The step is ambiguous", options: options) {
            CucumberTest.recordAmbiguousStep(step, on: self)
        }
    }

    func testAnAmbiguousStepFailsTheCurrentTestWhenNoRunningTestIsKnown() throws {
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else { throw XCTSkip("Needs XCTExpectFailure") }
        parseFeature(withSteps: "Given some precondition")
        Given("some precondition") { _, _ in }
        MatchAll("some precondition") { _, _ in }
        let step = try XCTUnwrap(steps.first)

        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { issue in issue.compactDescription.hasSuffix(CucumberTest.ambiguousStepMessage(for: step)) }
        XCTExpectFailure("The step is ambiguous", options: options) {
            CucumberTest.recordAmbiguousStep(step, on: nil)
        }
    }

    // The failure for an ambiguous step goes to the test XCTest is running.
    func testRunningTestCaseObserverTracksTheTestThatIsRunning() {
        let observer = RunningTestCaseObserver()
        let first = XCTestCase()
        let second = XCTestCase()

        observer.testCaseWillStart(first)
        XCTAssertIdentical(observer.testCase, first)

        observer.testCaseDidFinish(second)
        XCTAssertIdentical(observer.testCase, first, "Another test finishing leaves the running one in place")

        observer.testCaseDidFinish(first)
        XCTAssertNil(observer.testCase)
    }

    func testCucumberRecordsOnTheTestThatIsRunning() {
        XCTAssertIdentical(Cucumber.shared.runningTestCase, self)
    }
}
