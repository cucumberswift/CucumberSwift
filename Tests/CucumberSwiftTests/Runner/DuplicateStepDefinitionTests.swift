//
//  DuplicateStepDefinitionTests.swift
//  CucumberSwiftTests
//
//  Coverage for issue #37. As in cucumber-jvm (`DuplicateStepDefinitionException`), two step definitions
//  with the same pattern are an error at load time, whether or not a step uses them, when their keywords
//  can match the same steps.
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import CucumberSwift

class DuplicateStepDefinitionTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    private var errorLines: [Int?] { DuplicateStepDefinition.errors.map(\.line) }

    // The case reported in #37, with no feature at all: the duplicate is an error in itself.
    func testTheSamePatternTwiceIsADuplicateEvenWhenNoStepUsesIt() throws {
        let firstLine = #line + 1
        When("^the member goes to the messages screen$") { _, _ in }
        When("^the member goes to the messages screen$") { _, _ in }

        let problem = try XCTUnwrap(DuplicateStepDefinition.errors.first)
        XCTAssertEqual(DuplicateStepDefinition.errors.count, 1)
        XCTAssertEqual(problem.line, firstLine + 1)
        XCTAssertEqual(problem.file.map { URL(fileURLWithPath: $0).lastPathComponent }, "DuplicateStepDefinitionTests.swift")
        XCTAssertEqual(problem.message, "Duplicate step definitions at DuplicateStepDefinitionTests.swift:\(firstLine) and DuplicateStepDefinitionTests.swift:\(firstLine + 1): they have the same pattern and can match the same steps. Remove one of them.")
    }

    func testTheSameCucumberExpressionTwiceIsADuplicate() {
        Given("there are {int} flights") { _, _ in }
        let secondLine = #line + 1
        Given("there are {int} flights") { _, _ in }

        XCTAssertEqual(errorLines, [secondLine])
    }

    func testTheSameRegularExpressionThroughBothAPIsIsADuplicate() {
        Given("^there are (\\d+) flights$") { (_: [String], _) in }
        let secondLine = #line + 1
        Given("^there are (\\d+) flights$") { _, _ in }

        XCTAssertEqual(errorLines, [secondLine])
    }

    func testEachRepeatIsReportedAgainstTheFirst() {
        let firstLine = #line + 1
        Then("it works") { _, _ in }
        Then("it works") { _, _ in }
        Then("it works") { _, _ in }

        XCTAssertEqual(errorLines, [firstLine + 1, firstLine + 2])
        XCTAssertTrue(DuplicateStepDefinition.errors.allSatisfy { $0.message.contains("DuplicateStepDefinitionTests.swift:\(firstLine) and") })
    }

    // Keywords that can match the same step compete; ones that cannot, do not.
    func testMatchAllDuplicatesAnyKeyword() {
        Given("some precondition") { _, _ in }
        let secondLine = #line + 1
        MatchAll("some precondition") { _, _ in }

        XCTAssertEqual(errorLines, [secondLine])
    }

    func testAndDuplicatesAPrimaryKeyword() {
        When("some action") { _, _ in }
        let secondLine = #line + 1
        And("some action") { _, _ in }

        XCTAssertEqual(errorLines, [secondLine])
    }

    func testDifferentPrimaryKeywordsAreNotDuplicates() {
        Given("some text") { _, _ in }
        When("some text") { _, _ in }
        Then("some text") { _, _ in }

        XCTAssertEqual(errorLines, [])
    }

    func testAndAndButAreNotDuplicates() {
        And("some text") { _, _ in }
        But("some text") { _, _ in }

        XCTAssertEqual(errorLines, [])
    }

    func testCanCompete() {
        XCTAssertTrue(DuplicateStepDefinition.canCompete(nil, .when))
        XCTAssertTrue(DuplicateStepDefinition.canCompete(.given, nil))
        XCTAssertTrue(DuplicateStepDefinition.canCompete(.then, .then))
        XCTAssertTrue(DuplicateStepDefinition.canCompete(.but, .then))
        XCTAssertFalse(DuplicateStepDefinition.canCompete(.given, .then))
        XCTAssertFalse(DuplicateStepDefinition.canCompete(.and, .but))
    }

    // Different patterns that match the same step are not duplicates; that step fails as ambiguous instead.
    func testDifferentPatternsAreNotDuplicates() {
        Given("there are {int} flights") { _, _ in }
        Given("^there are (\\d+) flights$") { _, _ in }
        Given("/there are \\d+ flights/") { _, _ in }

        XCTAssertEqual(errorLines, [])
    }

    func testTestGherkinFailsEachDuplicateAtItsLine() throws {
        Given("some precondition") { _, _ in }
        let secondLine = #line + 1
        Given("some precondition") { _, _ in }

        var issues = [XCTIssue]()
        CucumberTest.reportInvalidRegularExpressions(DuplicateStepDefinition.errors) { issues.append($0) }

        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issue.sourceCodeContext.location?.fileURL.lastPathComponent, "DuplicateStepDefinitionTests.swift")
        XCTAssertEqual(issue.sourceCodeContext.location?.lineNumber, secondLine)
    }

    func testLoadingTheStepsAgainStartsOver() {
        Given("some precondition") { _, _ in }
        DuplicateStepDefinition.reset()
        Given("some precondition") { _, _ in }

        XCTAssertEqual(errorLines, [])
    }
}
