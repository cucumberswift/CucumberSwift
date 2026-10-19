//
//  StepTests.swift
//  CucumberSwiftTests
//
//  Created by thompsty on 7/22/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
import CucumberSwift

class DSLStepTests: XCTestCase {
    func testBasicDSL() {
        func printAStatement() { print("Printed") }

        let featureTitle = UUID().uuidString
        let scenarioTitle = UUID().uuidString

        let feature =
        Feature(featureTitle) {
            Description(UUID().uuidString)
            Scenario(scenarioTitle) {
                Given(I: printAStatement())
            }
        }

        XCTAssertEqual(feature.title, featureTitle)
        XCTAssertEqual(feature.location.line, 21)
        XCTAssertEqual(feature.location.column, 16)
        XCTAssertEqual(feature.scenarios.count, 1)

        let scenario = feature.scenarios.first
        XCTAssertEqual(scenario?.title, scenarioTitle)
        XCTAssertEqual(scenario?.location.line, 23)
        XCTAssertEqual(scenario?.location.column, 21)
        XCTAssertEqual(scenario?.steps.count, 1)

        let step = scenario?.steps.first
        XCTAssertEqual(step?.keyword, .given)
        XCTAssertEqual(step?.match, "I: printAStatement()")
        XCTAssertEqual(step?.location.line, 24)
        XCTAssertEqual(step?.location.column, 22)
    }

    func testStepMatchWithWeirdFormatting() {
        func printAStatement() { print("Printed") }

        let feature =
        Feature("") {
            Description(UUID().uuidString)
            Scenario("") {
                When(a:
                    printAStatement())
            }
        }

        let scenario = feature.scenarios.first
        let step = scenario?.steps.first
        XCTAssertEqual(step?.keyword, .when)
        XCTAssertEqual(step?.match, "a:printAStatement()")
        XCTAssertEqual(step?.location.line, 53)
        XCTAssertEqual(step?.location.column, 21)
    }

    func testStepMatchWithAsManyLineBreaksAsPossible() {
        func printAStatement() { print("Printed") }

        let feature =
        Feature("") {
            Description(UUID().uuidString)
            Scenario("") {
                Then(the:
                    printAStatement()
                )
            }
        }

        let scenario = feature.scenarios.first
        let step = scenario?.steps.first
        XCTAssertEqual(step?.keyword, .then)
        XCTAssertEqual(step?.match, "the:printAStatement()")
        XCTAssertEqual(step?.location.line, 73)
        XCTAssertEqual(step?.location.column, 21)
    }

    func testStepMatchWithAsStringLiteralThatTriesToFoolTheParenCount() {
        func printAStatement(_ str: String) { print(str) }

        let feature =
        Feature("") {
            Description(UUID().uuidString)
            Scenario("") {
                And(my:
                    printAStatement("))")
                )
            }
        }

        let scenario = feature.scenarios.first
        let step = scenario?.steps.first
        XCTAssertEqual(step?.keyword, .and)
        XCTAssertEqual(step?.match, "my:printAStatement(\"))\")")
        XCTAssertEqual(step?.location.line, 94)
        XCTAssertEqual(step?.location.column, 20)
    }

    func testStepMatchWithAsStringLiteralThatDoesNotTryToFoolTheParenCount() {
        func printAStatement(_ str: String) { print(str) }

        let feature =
        Feature("") {
            Description(UUID().uuidString)
            Scenario("") {
                But(some:
                    printAStatement("some other thing")
                )
            }
        }

        let scenario = feature.scenarios.first
        let step = scenario?.steps.first
        XCTAssertEqual(step?.keyword, .but)
        XCTAssertEqual(step?.match, "some:printAStatement(\"some other thing\")")
        XCTAssertEqual(step?.location.line, 115)
        XCTAssertEqual(step?.location.column, 20)
    }

    func testStepMatchWithAsDocStringLiteralThatDoesNotTryToFoolTheParenCount() {
        func printAStatement(_ str: String) { print(str) }

        let feature =
        Feature("") {
            Description(UUID().uuidString)
            Scenario("") {
                MatchAll(I:
                    printAStatement("""
                        ""some o)her thing""
                    """)
                )
            }
        }

        let scenario = feature.scenarios.first
        let step = scenario?.steps.first
        XCTAssertEqual(step?.keyword, [])
        XCTAssertEqual(step?.match, "I:printAStatement(\"\"\"\"\"some o)her thing\"\"\"\"\")")
        XCTAssertEqual(step?.location.line, 136)
        XCTAssertEqual(step?.location.column, 25)
    }

    func testTheMacroFormHasTheTextAndPositionItIsGiven() {
        func start() {}
        func signIn() async {}

        let feature =
        Feature("") {
            Scenario("") {
                Given(_macroStep: start(), stepText: "I: start()", line: 3, column: 9, file: "/Steps.swift")
                When(_macroStep: signIn, stepText: "I: signIn", line: 4, column: 8, file: "/Steps.swift")
            }
        }

        let steps = feature.scenarios.first?.steps ?? []
        XCTAssertEqual(steps.map(\.match), ["I: start()", "I: signIn"])
        XCTAssertEqual(steps.map(\.keyword), [.given, .when])
        XCTAssertEqual(steps.map(\.location.line), [3, 4])
        XCTAssertEqual(steps.map(\.location.column), [9, 8])
        XCTAssert(steps.allSatisfy(\.canExecute))
    }

    func testStepCanBeModifiedToNotContinueAfterFailure() {
        func printAStatement(_ str: String) { print(str) }

        let feature =
        Feature("") {
            Description(UUID().uuidString)
            Scenario("") {
                Given(I: printAStatement("")).continueAfterFailure(false)
            }
        }

        let scenario = feature.scenarios.first
        let step = scenario?.steps.first
        XCTAssertEqual(step?.continueAfterFailure, false)
    }
}
