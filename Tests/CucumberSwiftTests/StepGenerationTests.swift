//
//  StepGenerationTests.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 8/4/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//
// swiftlint:disable type_body_length

import Foundation
import XCTest
@testable import CucumberSwift

class StepGenerationTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
    }

    override func tearDownWithError() throws {
        Cucumber.shared.reset()
        Cucumber.overrideRegexLiteralStyle = .extendedDelimiter
    }

    func testGeneratedRegexUsesBareSlashesWhenAsked() {
        let cucumber = Cucumber(withString: """
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I login as "Dave"
        """)
        let actual = StubGenerator.getStubs(for: cucumber.features, regexLiteralStyle: .bareSlash)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(/^I login as \"(.*?)\"$/) { matches, _ in
            let string = matches.1
        }
        """#
        XCTAssertEqual(actual, expected)
    }

    func testGeneratedRegexReadsTheStyleFromTheStepImplementation() {
        let cucumber = Cucumber(withString: """
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given Some precondition
        """)
        XCTAssertEqual(StubGenerator.getStubs(for: cucumber.features).map(\.generatedSwift),
                       ["Given(#/^Some precondition$/#) { _, _ in\n\n}"])

        Cucumber.overrideRegexLiteralStyle = .bareSlash
        XCTAssertEqual(StubGenerator.getStubs(for: cucumber.features).map(\.generatedSwift),
                       ["Given(/^Some precondition$/) { _, _ in\n\n}"])
    }

    func testGeneratedRegexEscapesSlashesInBothStyles() {
        let cucumber = Cucumber(withString: """
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I open a/b and c/d
        """)
        XCTAssertEqual(StubGenerator.getStubs(for: cucumber.features, regexLiteralStyle: .extendedDelimiter).map(\.generatedSwift),
                       [#"Given(#/^I open a\/b and c\/d$/#) { _, _ in"# + "\n\n}"])
        XCTAssertEqual(StubGenerator.getStubs(for: cucumber.features, regexLiteralStyle: .bareSlash).map(\.generatedSwift),
                       [#"Given(/^I open a\/b and c\/d$/) { _, _ in"# + "\n\n}"])
    }

    func testGeneratedRegexKeepsAnEscapedSlashBeforeAHash() {
        // `\/#` does not end a `#/…/#` literal: Swift reads the escaped slash as part of the pattern.
        let cucumber = Cucumber(withString: ##"""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I open a/\#1
        """##)
        XCTAssertEqual(StubGenerator.getStubs(for: cucumber.features).map(\.generatedSwift),
                       [#"Given(#/^I open a\/#(\d+)$/#) { matches, _ in"# + "\n    let integer = matches.1\n}"])
    }

    func testGeneratedCapturesAreNumberedInTheOrderOfTheStep() {
        let cucumber = Cucumber(withString: """
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I pay 5 to "Sue" and 6 to "Bob"
        """)
        let actual = StubGenerator.getStubs(for: cucumber.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^I pay (\d+) to \"(.*?)\" and (\d+) to \"(.*?)\"$/#) { matches, _ in
            let integer = matches.1
            let string = matches.2
            let integerTwo = matches.3
            let stringTwo = matches.4
        }
        """#
        XCTAssertEqual(actual, expected)
    }

    func testGeneratedRegexWithGivenKeyword() {
        let cucumber = Cucumber(withString: """
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given Some precondition
        """)
        let actual = StubGenerator.getStubs(for: cucumber.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^Some precondition$/#) { _, _ in

        }
        """#
        XCTAssert(actual.contains(expected), "\"\(actual)\" does not contain \"\(expected)\"")
    }

    func testGeneratedRegexWithDifferentKeyword() {
        let cucumber = Cucumber(withString: """
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             When Some precondition
        """)
        let actual = StubGenerator.getStubs(for: cucumber.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        When(#/^Some precondition$/#) { _, _ in

        }
        """#
        XCTAssert(actual.contains(expected), "\"\(actual)\" does not contain \"\(expected)\"")
    }

    func testGeneratedRegexWithDifferentMatch() {
        let cucumber = Cucumber(withString: """
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             When A totally different string match
        """)
        let actual = StubGenerator.getStubs(for: cucumber.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        When(#/^A totally different string match$/#) { _, _ in

        }
        """#
        XCTAssert(actual.contains(expected), "\"\(actual)\" does not contain \"\(expected)\"")
    }

    func testGeneratedRegexWithLiteralsThatNeedToBeEscaped() {
        let cucumber = Cucumber(withString: """
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given A user with an idea(ish)
        """)
        let actual = StubGenerator.getStubs(for: cucumber.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^A user with an idea\(ish\)$/#) { _, _ in

        }
        """#
        XCTAssert(actual.contains(expected), "\"\(actual)\" does not contain \"\(expected)\"")
    }

    func testGeneratedRegexWithSomeStepsThatAreImplmentatedAndSomeThatAreNot() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given A user with an idea
              And A PO with two
        """)
        Given("A user with an idea") { _, _ in }
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^A PO with two$/#) { _, _ in

        }
        """#
        let notExpected = #"""
        Given(#/^A user with an idea$/#) { _, _ in

        }
        """#

        XCTAssert(actual.contains(expected), "\"\(actual)\" does not contain \"\(expected)\"")
        XCTAssert(!actual.contains(notExpected), "\"\(actual)\" should not contain \"\(notExpected)\"")
    }

    func testGeneratedRegexWithStringLiteral() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I login as "Dave"
        """)
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^I login as \"(.*?)\"$/#) { matches, _ in
            let string = matches.1
        }
        """#
        XCTAssert(actual.contains(expected), "\"\(actual)\" does not contain \"\(expected)\"")
    }

    func testGeneratedRegexWithMultipleStringLiterals() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I login as "Dave" with a password of "hello"
        """)
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^I login as \"(.*?)\" with a password of \"(.*?)\"$/#) { matches, _ in
            let string = matches.1
            let stringTwo = matches.2
        }
        """#
        XCTAssert(actual.contains(expected), "\"\(actual)\" does not contain \"\(expected)\"")
    }

    func testGeneratedRegexWithIntegerLiteral() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I login 1 time
        """)
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^I login (\d+) time$/#) { matches, _ in
            let integer = matches.1
        }
        """#
        XCTAssert(actual.contains(expected), "\"\(actual)\" does not contain \"\(expected)\"")
    }

    func testGeneratedRegexWithMultipleIntegerLiterals() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I enter 1234 then 4321
        """)
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^I enter (\d+) then (\d+)$/#) { matches, _ in
            let integer = matches.1
            let integerTwo = matches.2
        }
        """#
        XCTAssert(actual.contains(expected), "\"\(actual)\" does not contain \"\(expected)\"")
    }

    func testGeneratedRegexWithMultipleIdenticalMatchesButDifferentKeywords() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I login as "Dave"
               And I login as "Bobby"
             When I login as "Anne"
             Then I login as "Robert Downey Jr"
        """)
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        MatchAll(#/^I login as \"(.*?)\"$/#) { matches, _ in
            let string = matches.1
        }
        """#
        XCTAssertEqual(actual, expected)
    }

    func testGeneratedRegexWithMultipleIdenticalMatchesButDifferentKeywordsAndSomeAreAlreadyImplemented() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I login as "Dave"
               And I login as "Bobby"
             When I login as "Anne"
             Then I login as "Robert Downey Jr"
        """)
        Then("I login as {string}") { _, _ in }
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^I login as \"(.*?)\"$/#) { matches, _ in
            let string = matches.1
        }
        When(#/^I login as \"(.*?)\"$/#) { matches, _ in
            let string = matches.1
        }
        """#
        XCTAssertEqual(actual, expected)
    }

    func testGeneratedRegexHasCommentsIfItWillOverwriteAnotherStepImplementation() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
             Given I login as "Anne"
             Given I login as "Robert Downey Jr"
        """)
        Given("I login as \"Robert Downey Jr\"") { _, _ in }
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        //FIXME: WARNING: This will overwite your implementation for the step(s):
        //                Given I login as "Robert Downey Jr"
        Given(#/^I login as \"(.*?)\"$/#) { matches, _ in
            let string = matches.1
        }
        """#
        XCTAssertEqual(actual, expected)
    }

    func testGeneratedImplementationWhenStepContainsADataTable() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Unimplemented scenario with data table
               Given I have some data table that is not implemented
                   | tbl |
                   | foo |
        """)
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^I have some data table that is not implemented$/#) { _, step in
            let dataTable = step.dataTable
        }
        """#
        XCTAssertEqual(actual, expected)
    }

    func testGeneratedImplementationWhenStepContainsADocString() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Unimplemented scenario with DocString
               Given a DocString of some kind that is not implemented
               ```xml
               <foo>
                   <bar />
               </foo>
               ```
        """)
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^a DocString of some kind that is not implemented$/#) { _, step in
            let docString = step.docString
        }
        """#
        XCTAssertEqual(actual, expected)
    }

    func testComplexGenerationWithManyValues() {
        Cucumber.shared.features.removeAll()
        Cucumber.shared.parseIntoFeatures("""
        Feature: Some terse yet descriptive text of what is desired
            Scenario: Unimplemented scenario with data table
                Given I have some data table that is not implemented and some string "blah" and some other string "lbah"
                   | tbl |
                   | foo |
                    And a DocString with the number 123 and another number 456
                    ```xml
                    <foo>
                        <bar />
                    </foo>
                    ```
        """)
        let actual = StubGenerator.getStubs(for: Cucumber.shared.features)
            .map(\.generatedSwift)
            .joined(separator: "\n")
        let expected = #"""
        Given(#/^I have some data table that is not implemented and some string \"(.*?)\" and some other string \"(.*?)\"$/#) { matches, step in
            let string = matches.1
            let stringTwo = matches.2
            let dataTable = step.dataTable
        }
        Given(#/^a DocString with the number (\d+) and another number (\d+)$/#) { matches, step in
            let integer = matches.1
            let integerTwo = matches.2
            let docString = step.docString
        }
        """#
        XCTAssertEqual(actual, expected)
    }
}
