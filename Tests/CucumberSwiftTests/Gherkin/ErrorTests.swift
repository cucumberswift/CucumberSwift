//
//  ErrorTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 10/6/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
@testable import CucumberSwift

class ErrorsTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
    }

    func testNotGherkin() {
        Cucumber.shared.parseIntoFeatures("""
            Not Gherkin
        """, uri: "test.feature")
        XCTAssert(Gherkin.errors.contains("File: test.feature does not contain any valid gherkin"))
    }
    func testInvalidLanguage() {
        Cucumber.shared.parseIntoFeatures("""
            #language:no-such

            Feature: Minimal

              Scenario: minimalistic
                Given the minimalism
        """, uri: "failedLanguage.feature")
        XCTAssert(Gherkin.errors.contains("File: failedLanguage.feature declares an unsupported language"))
    }

    func testUnexpectedEndOfFile() {
        Cucumber.shared.parseIntoFeatures("""
            Feature: Unexpected end of file

            Scenario Outline: minimalistic
              Given the minimalism

              @tag
        """, uri: "unexpected_eof.feature")
        XCTAssert(Gherkin.errors.contains("File: unexpected_eof.feature unexpected end of file, expected: #TagLine, #ScenarioLine, #Comment, #Empty"))
    }

    func testInconsistenCellCount() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Inconsistent cell counts

        Scenario: minimalistic
          Given a data table with inconsistent cell count
            | foo | bar |
            | boz |


        Scenario Outline: minimalistic
          Given the <what>

        Examples:
          | what       |
          | minimalism | extra |
        """, uri: "inconsistent_cell_count.feature")
        XCTAssert(Gherkin.errors.contains("File: inconsistent_cell_count.feature inconsistent cell count within the table"))
    }

    func testSingleParserError() {
        Cucumber.shared.parseIntoFeatures("""

        invalid line here

        Feature: Single parser error

          Scenario: minimalistic
            Given the minimalism
        """, uri: "single_parser_error.feature")
        XCTAssert(Gherkin.errors.contains("File: single_parser_error.feature, expected: #EOF, #Language, #TagLine, #FeatureLine, #Comment, #Empty, got 'invalid line here'"))
    }

    func testDuplicateStepTextInScenario() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Duplicate steps

          Scenario: duplicated
            Given some setup
            Then the candidates appear in this order:
              | candidate |
              | hello     |
              | world     |
            When some action
            Then the candidates appear in this order:
              | candidate |
              | foo       |
              | bar       |
        """, uri: "duplicate_step.feature")
        XCTAssert(Gherkin.errors.contains(where: { $0.contains("duplicate step") }))
    }

    func testDuplicateStepErrorMessage() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Duplicate steps

          Scenario: duplicated
            Then do something
            Then do something
        """, uri: "dup.feature")
        XCTAssert(Gherkin.errors.contains("File: dup.feature duplicate step 'Then do something' in scenario 'duplicated'"))
    }

    func testNoDuplicateErrorForUniqueSteps() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Unique steps

          Scenario: unique
            Given step one
            When step two
            Then step three
        """, uri: "unique.feature")
        XCTAssertFalse(Gherkin.errors.contains(where: { $0.contains("duplicate step") }))
    }

    func testSameStepTextInDifferentScenariosIsAllowed() {
        Cucumber.shared.parseIntoFeatures("""
        Feature: Shared steps across scenarios

          Scenario: first
            Given some setup
            Then verify result

          Scenario: second
            Given some setup
            Then verify result
        """, uri: "cross_scenario.feature")
        XCTAssertFalse(Gherkin.errors.contains(where: { $0.contains("duplicate step") }))
    }

    override func tearDown() {
        Gherkin.errors.removeAll()
    }
}
