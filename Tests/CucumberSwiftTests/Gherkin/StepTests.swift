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
    /// `""` on every execution, which always throws. The throw was swallowed, so the only symptom
    /// was a console line nobody read.
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
        XCTAssert(Gherkin.errors.isEmpty,
                  "Executing a DSL step should not compile a regex. Errors:\n\(Gherkin.errors.joined(separator: "\n"))")
    }
}
