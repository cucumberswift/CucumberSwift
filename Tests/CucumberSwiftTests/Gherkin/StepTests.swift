//
//  StepTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 7/22/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
@testable import CucumberSwift

class StepTest: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testAsteriskMatchesToGiven() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssert(firstStep?.keyword.contains(.given) ?? false)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var givenCalled = false
        Given("a user with half a clue") { _, _ in
            givenCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(givenCalled)
    }

    func testAsteriskMatchesToWhen() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssert(firstStep?.keyword.contains(.when) ?? false)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var whenCalled = false
        When("a user with half a clue") { _, _ in
            whenCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(whenCalled)
    }

    func testAsteriskMatchesToThen() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssert(firstStep?.keyword.contains(.then) ?? false)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var thenCalled = false
        Then("a user with half a clue") { _, _ in
            thenCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(thenCalled)
    }

    func testAsteriskMatchesToAnd() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssert(firstStep?.keyword.contains(.and) ?? false)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var andCalled = false
        And("a user with half a clue") { _, _ in
            andCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(andCalled)
    }

    func testAsteriskMatchesToBut() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssert(firstStep?.keyword.contains(.but) ?? false)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var butCalled = false
        But("a user with half a clue") { _, _ in
            butCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(butCalled)
    }

    func testAsteriskMatchesToMatchAll() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         * a user with half a clue
    """)
        let feature = Cucumber.shared.features.first
        let scenario = feature?.scenarios.first
        let firstStep = scenario?.steps.first
        XCTAssertEqual(scenario?.steps.count, 1)
        XCTAssertEqual(firstStep?.match, "a user with half a clue")
        var matchAllCalled = false
        MatchAll("a user with half a clue") { _, _ in
            matchAllCalled = true
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(matchAllCalled)
    }

    func testKeywordHasMultipleValues() {
        XCTAssertFalse(Step.Keyword.given.hasMultipleValues())
        XCTAssertFalse(Step.Keyword.when.hasMultipleValues())
        XCTAssertFalse(Step.Keyword.then.hasMultipleValues())
        XCTAssertFalse(Step.Keyword.and.hasMultipleValues())
        XCTAssertFalse(Step.Keyword.but.hasMultipleValues())
        var kw: Step.Keyword = []
        XCTAssertFalse(kw.hasMultipleValues())

        kw = [.given, .when]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.given, .then]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.given, .and]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.given, .but]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.when, .then]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.when, .and]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.then, .and]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.then, .but]
        XCTAssertTrue(kw.hasMultipleValues())
        kw = [.and, .but]
        XCTAssertTrue(kw.hasMultipleValues())
    }

    /// Regression test for #135: a step built by the Swift DSL used to compile the empty pattern
    /// `""` on every execution, which always throws. An uncompilable pattern is now recorded in
    /// `RegularExpression.errors`, so that is where the bug would show if it came back.
    func testExecutingADSLStepDoesNotCompileARegex() throws {
        var handlerCalled = false
        let step = GivenStep(line: 1,
                             column: 1,
                             match: "a step defined with the Swift DSL",
                             handler: { handlerCalled = true },
                             file: #file)

        let execute = try XCTUnwrap(step.execute)
        try execute(step.match, step)

        XCTAssert(handlerCalled)
        XCTAssert(RegularExpression.errors.isEmpty,
                  "Executing a DSL step should not compile a regex. Errors:\n\(RegularExpression.errors.map(\.message).joined(separator: "\n"))")
    }

    /// #218: a step definition's regex that will not compile is reported at the step definition,
    /// so Xcode marks the consumer's own line rather than a line inside CucumberSwift.
    func testAStringRegexThatWillNotCompileIsRecordedAtItsStepDefinition() {
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some feature
       Scenario: Some determinable business situation
         When a broken step runs
    """)
        let pattern: String = "^a broken (step runs$"

        When(pattern, callback: { _, _ in }, line: 42, file: "StepDefinitions.swift")

        XCTAssertEqual(RegularExpression.errors.count, 1, "The pattern should be recorded once, with its location")
        let problem = RegularExpression.errors.first
        XCTAssertEqual(problem?.file, "StepDefinitions.swift")
        XCTAssertEqual(problem?.line, 42)
        XCTAssert(problem?.message.contains(pattern) ?? false)
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
            XCTAssert(problem?.message.hasSuffix("expected ')'") ?? false,
                      "The message should say what is wrong with the pattern: \(problem?.message ?? "")")
        }
        XCTAssertNil(Cucumber.shared.features.first?.scenarios.first?.steps.first?.execute,
                     "A pattern that will not compile can never match, so it should not be attached")
    }

    /// `testGherkin()` reports each pattern that will not compile as a failure: at its step
    /// definition when it has one, so Xcode marks the consumer's line, and otherwise from CucumberSwift.
    func testInvalidRegularExpressionsAreReportedAtTheirStepDefinitions() throws {
        let problems = [
            RegularExpression.Problem(message: "Invalid regular expression '^(': expected ')'",
                                      file: "/tmp/StepDefinitions.swift",
                                      line: 42),
            RegularExpression.Problem(message: "Invalid regular expression '@(': expected ')'", file: nil, line: nil)
        ]
        var issues = [XCTIssue]()

        CucumberTest.reportInvalidRegularExpressions(problems, file: "/tmp/CucumberTest.swift", line: 7) { issues.append($0) }

        XCTAssertEqual(issues.count, 2)
        let located = try XCTUnwrap(issues.first)
        XCTAssertEqual(located.type, .assertionFailure)
        XCTAssertEqual(located.compactDescription, "Invalid regular expression '^(': expected ')'")
        XCTAssertEqual(located.sourceCodeContext.location?.fileURL, URL(fileURLWithPath: "/tmp/StepDefinitions.swift"))
        XCTAssertEqual(located.sourceCodeContext.location?.lineNumber, 42)
        let unlocated = try XCTUnwrap(issues.last)
        XCTAssert(unlocated.compactDescription.hasPrefix("Invalid regular expression '@(': expected ')' (in CUCUMBER_TAGS"),
                  unlocated.compactDescription)
        XCTAssertEqual(unlocated.sourceCodeContext.location?.fileURL, URL(fileURLWithPath: "/tmp/CucumberTest.swift"))
        XCTAssertEqual(unlocated.sourceCodeContext.location?.lineNumber, 7)
    }
}
