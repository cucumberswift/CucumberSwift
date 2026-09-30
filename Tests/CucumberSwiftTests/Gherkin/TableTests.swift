//
//  TableTests.swift
//  CucumberSwiftTests
//
//  Created by dev1 on 7/17/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//
// swiftlint:disable all

import Foundation
import XCTest
import CucumberSwiftExpressions
@testable import CucumberSwift

class TableTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    let tableFile: String =
    """
    Feature: Some terse yet descriptive text of what is desired
        Textual description of the business value of this feature
        Business rules that govern the scope of the feature
        Any additional information that will make the feature easier to understand

        Scenario Outline: Some determinable business situation
            Given some <precondition>
                And some <other precondition>
            When some action by <actor>
            Then some <testable outcome> is achieved

            Examples:
                | precondition  | other precondition    | actor | testable outcome  |
                | first         | second                | Bob   | result 1          |
                | third         | fourth                | Susan | result 2          |
    """

    func testTableDataIsDuplicatedAcrossScenarios() {
        let cucumber = Cucumber(withString: tableFile)
        let feature = cucumber.features.first
        let firstScenario = feature?.scenarios.first
        let secondScenario = feature?.scenarios.last
        XCTAssertEqual(feature?.scenarios.count, 2)
        XCTAssertEqual(firstScenario?.steps.count, 4)
        XCTAssertEqual(secondScenario?.steps.count, 4)
        XCTAssertEqual(firstScenario?.title, "Some determinable business situation (example 1)")
        XCTAssertEqual(secondScenario?.title, "Some determinable business situation (example 2)")
        if (firstScenario?.steps.count ?? 0) == 4 {
            let steps = firstScenario?.steps
            XCTAssertEqual(steps?[0].keyword, .given)
            XCTAssertEqual(steps?[0].match, "some first")
            XCTAssertEqual(steps?[1].keyword, [.given, .and])
            XCTAssertEqual(steps?[1].match, "some second")
            XCTAssertEqual(steps?[2].keyword, .when)
            XCTAssertEqual(steps?[2].match, "some action by Bob")
            XCTAssertEqual(steps?[3].keyword, .then)
            XCTAssertEqual(steps?[3].match, "some result 1 is achieved")
        }
        if (secondScenario?.steps.count ?? 0) == 4 {
            let steps = secondScenario?.steps
            XCTAssertEqual(steps?[0].keyword, .given)
            XCTAssertEqual(steps?[0].match, "some third")
            XCTAssertEqual(steps?[1].keyword, [.given, .and])
            XCTAssertEqual(steps?[1].match, "some fourth")
            XCTAssertEqual(steps?[2].keyword, .when)
            XCTAssertEqual(steps?[2].match, "some action by Susan")
            XCTAssertEqual(steps?[3].keyword, .then)
            XCTAssertEqual(steps?[3].match, "some result 2 is achieved")
        }
    }

    func testScenarioOutlinesHandleBackgroundSteps() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
        Textual description of the business value of this feature
        Business rules that govern the scope of the feature
        Any additional information that will make the feature easier to understand

        Background:
            Given I am logged in

        Scenario Outline: Some determinable business situation
            Given some <precondition>
                And some <other precondition>
            When some action by <actor>
            Then some <testable outcome> is achieved

            Examples:
                | precondition  | other precondition    | actor | testable outcome  |
                | first         | second                | Bob   | result 1          |
                | third         | fourth                | Susan | result 2          |
    """)
        let feature = cucumber.features.first
        XCTAssertEqual(feature?.scenarios.count, 2)
        feature?.scenarios.enumerated().forEach({ (index, scenario) in
            let exampleNumber = index + 1
            XCTAssertEqual(scenario.title, "Some determinable business situation (example \(exampleNumber))")
            XCTAssertEqual(scenario.steps.count, 5)
        })
    }

    func testScenarioOutlinesHandleTags() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
        Textual description of the business value of this feature
        Business rules that govern the scope of the feature
        Any additional information that will make the feature easier to understand

        Background:
            Given I am logged in

        @outline
        Scenario Outline: Some determinable business situation
            Given some <precondition>
                And some <other precondition>
            When some action by <actor>
            Then some <testable outcome> is achieved

            Examples:
                | precondition  | other precondition    | actor | testable outcome  |
                | first         | second                | Bob   | result 1          |
                | third         | fourth                | Susan | result 2          |
    """)
        let feature = cucumber.features.first
        XCTAssertEqual(feature?.scenarios.count, 2)
        feature?.scenarios.enumerated().forEach({ (index, scenario) in
            let exampleNumber = index + 1
            XCTAssertEqual(scenario.title, "Some determinable business situation (example \(exampleNumber))")
            XCTAssertEqual(scenario.steps.count, 5)
            XCTAssert(scenario.containsTag("outline"))
        })
    }

    func testTableHeadersInsideTitle() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
      Scenario Outline: the <one>
        Given the <four>

            Examples:
              | one | two  | three | four   | five  |
              | un  | deux | trois | quatre | cinq  |
              | uno | dos  | tres  | quatro | cinco |
    """)
        let firstScenario = cucumber.features.first?.scenarios.first
        let secondScenario = cucumber.features.first?.scenarios.last
        XCTAssertEqual(firstScenario?.title, "the un (example 1)")
        XCTAssertEqual(secondScenario?.title, "the uno (example 2)")
    }

    func testTableCellWithEscapeCharacter() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
      Scenario Outline: the <one>
        Given the <two>

            Examples:
              | one   | two  |
              | u\\|o | dos  |
    """)
        let firstScenario = cucumber.features.first?.scenarios.first
        XCTAssertEqual(firstScenario?.title, "the u|o (example 1)")
    }

    func testTableCellInQuotes() {
        let cucumber = Cucumber(withString: """
    Feature: Some terse yet descriptive text of what is desired
      Scenario Outline: the "<one>"
        Given the "<two>"

            Examples:
              | one   | two  |
              | u\\|o | dos  |
    """)
        let firstScenario = cucumber.features.first?.scenarios.first
        XCTAssertEqual(firstScenario?.title, "the \"u|o\" (example 1)")
        XCTAssertEqual(firstScenario?.steps.first?.match, "the \"dos\"")
    }

    func testTableGetAttachedToSteps() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some terse yet descriptive text of what is desired
      Scenario Outline: Some Table
        Given the <one>

            Examples:
              | one | two  |
              | un  | deux |
              | uno | dos  |
    """)
        var firstGivenCalled = false
        Given("the un") { _, _ in
            firstGivenCalled = true
        }
        var secondGivenCalled = false
        Given("the uno") { _, _ in
            secondGivenCalled = true
        }

        Cucumber.shared.executeFeatures()

        waitUntil(firstGivenCalled)
        waitUntil(secondGivenCalled)
        XCTAssert(firstGivenCalled)
        XCTAssert(secondGivenCalled)
    }

    func testExamplesCanAffectDataTableOnAStep() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Sample

        Scenario Outline: Sample scenario
            Then I have a sample step with a=<paramA>,b=<paramB>
                | a        | b        |
                | <paramA> | <paramB> |

            Examples:
                | paramA | paramB |
                | 0      | 1      |
                | 5      | 10     |
        """)
        var thenCalled = 0
        Then("I have a sample step with a={int},b={int}" as CucumberExpression) { matches, step in
            defer { thenCalled += 1 }
            if thenCalled < 1 {
                XCTAssertEqual(matches[\.int, index: 0], 0)
                XCTAssertEqual(matches[\.int, index: 1], 1)

                let dataTable = try XCTUnwrap(step.dataTable)

                XCTAssertEqual(dataTable.rows.count, 2)
                guard dataTable.rows.count == 2 else { return }
                XCTAssertEqual(dataTable.rows[0].count, 2)
                XCTAssertEqual(dataTable.rows[1].count, 2)
                guard dataTable.rows[0].count == 2,
                      dataTable.rows[1].count == 2 else { return }

                XCTAssertEqual(dataTable.rows[0][0], "a")
                XCTAssertEqual(dataTable.rows[0][1], "b")
                XCTAssertEqual(dataTable.rows[1][0], "0")
                XCTAssertEqual(dataTable.rows[1][1], "1")
            } else {
                XCTAssertEqual(matches[\.int, index: 0], 5)
                XCTAssertEqual(matches[\.int, index: 1], 10)

                let dataTable = try XCTUnwrap(step.dataTable)

                XCTAssertEqual(dataTable.rows.count, 2)
                guard dataTable.rows.count == 2 else { return }
                XCTAssertEqual(dataTable.rows[0].count, 2)
                XCTAssertEqual(dataTable.rows[1].count, 2)
                guard dataTable.rows[0].count == 2,
                      dataTable.rows[1].count == 2 else { return }

                XCTAssertEqual(dataTable.rows[0][0], "a")
                XCTAssertEqual(dataTable.rows[0][1], "b")
                XCTAssertEqual(dataTable.rows[1][0], "5")
                XCTAssertEqual(dataTable.rows[1][1], "10")
            }
        }

        Cucumber.shared.executeFeatures()

        waitUntil(thenCalled == 2)
        XCTAssertEqual(thenCalled, 2)
    }

    func testUnclosedTableHeader() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Sample
            Scenario: Scenario description
                Given Something
                When Something is done
                Then the data looks like:
                  | speed   |  <9000 |
                  | size    | >12000 |
        """)

        let scenario = Cucumber.shared.features.first?.scenarios.first
        let step = scenario?.steps.last
        let table = step?.dataTable
        let firstRow = table?.rows.first
        XCTAssertNotNil(step?.dataTable)
        XCTAssertEqual(table?.rows.count, 2)
        XCTAssertEqual(firstRow?.count, 2)
        guard table?.rows.count == 2, firstRow?.count == 2 else { return }
        XCTAssertEqual(firstRow?[0], "speed")
        XCTAssertEqual(firstRow?[1], "<9000")

        XCTAssertEqual(table?.rows[1][0], "size")
        XCTAssertEqual(table?.rows[1][1], ">12000")

        XCTAssert(Gherkin.errors.snapshot.isEmpty)
        Cucumber.shared.executeFeatures()
    }

    func testDataTableOnStepCanEscape() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures(#"""
        Feature: Sample

        Scenario: minimalistic
            Given a simple data table
            | \<foo\> | \<bar\> |
        """#)
        var givenCalled = 0
        Given("a simple data table") { matches, step in
            defer { givenCalled += 1 }
            let dataTable = try XCTUnwrap(step.dataTable)

            XCTAssertEqual(dataTable.rows.count, 1)
            guard dataTable.rows.count == 1 else { return }
            XCTAssertEqual(dataTable.rows[0].count, 2)
            guard dataTable.rows[0].count == 2 else { return }

            XCTAssertEqual(dataTable.rows[0][0], "<foo>")
            XCTAssertEqual(dataTable.rows[0][1], "<bar>")
        }

        Cucumber.shared.executeFeatures()

        waitUntil(givenCalled > 0)
        XCTAssertEqual(givenCalled, 1)
    }

    func testTestDataAttachedToAStep() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some terse yet descriptive text of what is desired
        Scenario: minimalistic
            Given a simple data table
            | foo | bar |
            | boz | boo |
    """)
        let scenario = Cucumber.shared.features.first?.scenarios.first
        let step = scenario?.steps.first
        let table = step?.dataTable
        let firstRow = table?.rows.first
        let secondRow = table?.rows.last
        XCTAssertNotNil(step?.dataTable)
        XCTAssertEqual(table?.rows.count, 2)
        XCTAssertEqual(firstRow?.count, 2)
        XCTAssertEqual(secondRow?.count, 2)
        if (firstRow?.count ?? 0) == 2 {
            XCTAssertEqual(firstRow?[0], "foo")
            XCTAssertEqual(firstRow?[1], "bar")
        }
        if (secondRow?.count ?? 0) == 2 {
            XCTAssertEqual(secondRow?[0], "boz")
            XCTAssertEqual(secondRow?[1], "boo")
        }
        var givenCalled = false
        if step?.dataTable != nil {
            Given("a simple data table") { (_, step) in
                givenCalled = true
                let dt = step.dataTable!
                let firstRow = dt.rows.first!
                let secondRow = dt.rows.last!
                XCTAssertEqual(firstRow[0], "foo")
                XCTAssertEqual(firstRow[1], "bar")
                XCTAssertEqual(secondRow[0], "boz")
                XCTAssertEqual(secondRow[1], "boo")
            }
        }
        Cucumber.shared.executeFeatures()
        XCTAssert(givenCalled)
    }

    func testTestDataAttachedToAStepWithEmptyCell() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
    Feature: Some terse yet descriptive text of what is desired
        Scenario: minimalistic
            Given a simple data table
            | foo || bar |
    """)
        let scenario = Cucumber.shared.features.first?.scenarios.first
        let step = scenario?.steps.first
        let table = step?.dataTable
        let firstRow = table?.rows.first
        XCTAssertNotNil(step?.dataTable)
        XCTAssertEqual(table?.rows.count, 1)
        XCTAssertEqual(firstRow?.count, 3)
        if (firstRow?.count ?? 0) == 3 {
            XCTAssertEqual(firstRow?[0], "foo")
            XCTAssertEqual(firstRow?[1], "")
            XCTAssertEqual(firstRow?[2], "bar")
        }
        Cucumber.shared.executeFeatures()
    }

    func testComplexDataAttachedToStep() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
            Scenario: minimalistic
                Given a simple data table
                Then  User should see log entries:
                      | TYPE    | NAME       | SUMMARY              | LABEL     | ACTIONS |
                      | missed  | 01/06/2021 | Missed check         |           | <none>  |
                      | missed  | 01/05/2021 | Missed check         |           | <none>  |
                      | checked | 01/04/2021 | Logged by Test user  |           | <none>  |
                      | checked | 01/03/2021 | Logged by Test user  |           | <none>  |
                      | ignored | 01/02/2021 | Ignored by Test user | (Ignored) | <none>  |
                      | ignored | 01/01/2021 | Ignored by Test user | (Ignored) | <none>  |
        """)
        let scenario = Cucumber.shared.features.first?.scenarios.first
        let step = scenario?.steps.last
        let table = step?.dataTable
        let firstRow = table?.rows.first
        XCTAssertNotNil(step?.dataTable)
        XCTAssertEqual(table?.rows.count, 7)
        XCTAssertEqual(firstRow?.count, 5)
        guard table?.rows.count == 7, firstRow?.count == 5 else { return }
        XCTAssertEqual(firstRow?[0], "TYPE")
        XCTAssertEqual(firstRow?[1], "NAME")
        XCTAssertEqual(firstRow?[2], "SUMMARY")
        XCTAssertEqual(firstRow?[3], "LABEL")
        XCTAssertEqual(firstRow?[4], "ACTIONS")

        XCTAssertEqual(table?.rows[1][0], "missed")
        XCTAssertEqual(table?.rows[1][1], "01/06/2021")
        XCTAssertEqual(table?.rows[1][2], "Missed check")
        XCTAssertEqual(table?.rows[1][3], "")
        XCTAssertEqual(table?.rows[1][4], "<none>")

        XCTAssertEqual(table?.rows[2][0], "missed")
        XCTAssertEqual(table?.rows[2][1], "01/05/2021")
        XCTAssertEqual(table?.rows[2][2], "Missed check")
        XCTAssertEqual(table?.rows[2][3], "")
        XCTAssertEqual(table?.rows[2][4], "<none>")

        XCTAssertEqual(table?.rows[3][0], "checked")
        XCTAssertEqual(table?.rows[3][1], "01/04/2021")
        XCTAssertEqual(table?.rows[3][2], "Logged by Test user")
        XCTAssertEqual(table?.rows[3][3], "")
        XCTAssertEqual(table?.rows[3][4], "<none>")

        XCTAssertEqual(table?.rows[4][0], "checked")
        XCTAssertEqual(table?.rows[4][1], "01/03/2021")
        XCTAssertEqual(table?.rows[4][2], "Logged by Test user")
        XCTAssertEqual(table?.rows[4][3], "")
        XCTAssertEqual(table?.rows[4][4], "<none>")

        XCTAssertEqual(table?.rows[5][0], "ignored")
        XCTAssertEqual(table?.rows[5][1], "01/02/2021")
        XCTAssertEqual(table?.rows[5][2], "Ignored by Test user")
        XCTAssertEqual(table?.rows[5][3], "(Ignored)")
        XCTAssertEqual(table?.rows[5][4], "<none>")

        XCTAssertEqual(table?.rows[6][0], "ignored")
        XCTAssertEqual(table?.rows[6][1], "01/01/2021")
        XCTAssertEqual(table?.rows[6][2], "Ignored by Test user")
        XCTAssertEqual(table?.rows[6][3], "(Ignored)")
        XCTAssertEqual(table?.rows[6][4], "<none>")

        XCTAssert(Gherkin.errors.snapshot.isEmpty)
        Cucumber.shared.executeFeatures()
    }

    func testScenarioOutlineWithMultipleExamples() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Tagged Examples

        Scenario Outline: minimalistic
          Given the <what>

          Examples:
            | what |
            | foo  |

          Examples:
            | what |
            | bar  |

        Scenario: ha ok
        """)
        XCTAssertEqual(Cucumber.shared.features.count, 1)
        let feature = Cucumber.shared.features.first
        XCTAssertEqual(feature?.scenarios.count, 3)
        XCTAssertEqual(feature?.scenarios[safe: 0]?.steps.count, 1)
        XCTAssertEqual(feature?.scenarios[safe: 0]?.steps.first?.keyword, .given)
        XCTAssertEqual(feature?.scenarios[safe: 0]?.steps.first?.match, "the foo")
        XCTAssertEqual(feature?.scenarios[safe: 0]?.steps.first?.keyword, .given)
        XCTAssertEqual(feature?.scenarios[safe: 1]?.steps.count, 1)
        XCTAssertEqual(feature?.scenarios[safe: 1]?.steps.first?.keyword, .given)
        XCTAssertEqual(feature?.scenarios[safe: 1]?.steps.first?.match, "the bar")
    }
}
