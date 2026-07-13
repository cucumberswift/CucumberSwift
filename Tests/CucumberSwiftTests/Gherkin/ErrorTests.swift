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

    override func tearDown() {
        Gherkin.errors.removeAll()
    }
}
