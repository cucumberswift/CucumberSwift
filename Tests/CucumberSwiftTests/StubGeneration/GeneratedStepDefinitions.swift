//
//  GeneratedStepDefinitions.swift
//  CucumberSwiftTests
//
// swiftlint:disable all

import Foundation
import XCTest
import CucumberSwift

/// The step definitions CucumberSwift generates for `feature`, pasted in unchanged: Cucumber
/// Expressions, the default, in `registerCucumberExpressions()`, and regex literals in the `#/…/#`
/// style in `register()`. Compiling this file proves the generated code compiles in a target without
/// bare slash regex literals (SwiftPM builds this one in the Swift 5 language mode), and
/// `GeneratedStepDefinitionTests` checks that the code still matches the generator's output and
/// that it matches every step of `feature`.
///
/// If the generator changes, replace everything between the BEGIN and END lines with the output
/// the failing test prints.
enum GeneratedStepDefinitions {
    // `\#` is Gherkin's escape for a literal `#`, so the raw string needs `##`.
    static let feature = ##"""
    Feature: Generated step definitions
      Scenario: Every kind of generated step definition
        Given a step with no parameters
        And a step with (brackets), [square brackets], a/slash, a price of $5.00? and a star*
        When I log in as "Dave" with the password "secret"
        And I pay 5 to "Sue" and 6 to "Bob"
        Then I see 3 messages
        And the temperature is -5 degrees
        And I owe 5$
        And ^a caret and {braces}
        And I open the path a/\#b
        And a data table
          | a | b |
          | 1 | 2 |
        And a doc string
          """
          some text
          """
      Scenario: The same step with different keywords
        Given a repeated step
        When a repeated step
    """##

    static func registerCucumberExpressions() {
        // BEGIN GENERATED CUCUMBER EXPRESSIONS
        Given("a step with no parameters") { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        MatchAll("a repeated step") { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        When("I log in as {string} with the password {string}") { match, _ in
            let string = match[\.string, index: 0]
            let stringTwo = match[\.string, index: 1]
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then("I see {int} messages") { match, _ in
            let int = try match.first(\.int)
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Given("a step with \\(brackets), [square brackets], a\\/slash, a price of ${float}? and a star*") { match, _ in
            let float = try match.first(\.float)
            XCTFail("Step not implemented: replace this line with your test code")
        }
        When("I pay {int} to {string} and {int} to {string}") { match, _ in
            let int = match[\.int, index: 0]
            let string = match[\.string, index: 0]
            let intTwo = match[\.int, index: 1]
            let stringTwo = match[\.string, index: 1]
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then("the temperature is {int} degrees") { match, _ in
            let int = try match.first(\.int)
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then("^I owe (\\d+)\\$$") { match, _ in
            let string = match[\.anonymous, index: 0]
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then("\\^a caret and \\{braces}") { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then("I open the path a\\/#b") { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then("a data table") { _, step in
            let dataTable = step.dataTable
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then("a doc string") { _, step in
            let docString = step.docString
            XCTFail("Step not implemented: replace this line with your test code")
        }
        // END GENERATED CUCUMBER EXPRESSIONS
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
    static func register() {
        // BEGIN GENERATED
        Given(#/^a step with no parameters$/#) { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        MatchAll(#/^a repeated step$/#) { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        When(#/^I log in as \"(.*?)\" with the password \"(.*?)\"$/#) { matches, _ in
            let string = matches.1
            let stringTwo = matches.2
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then(#/^I see (\d+) messages$/#) { matches, _ in
            let integer = matches.1
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Given(#/^a step with \(brackets\), \[square brackets], a\/slash, a price of \$(\d+)\.(\d+)\? and a star\*$/#) { matches, _ in
            let integer = matches.1
            let integerTwo = matches.2
            XCTFail("Step not implemented: replace this line with your test code")
        }
        When(#/^I pay (\d+) to \"(.*?)\" and (\d+) to \"(.*?)\"$/#) { matches, _ in
            let integer = matches.1
            let string = matches.2
            let integerTwo = matches.3
            let stringTwo = matches.4
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then(#/^the temperature is -(\d+) degrees$/#) { matches, _ in
            let integer = matches.1
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then(#/^I owe (\d+)\$$/#) { matches, _ in
            let integer = matches.1
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then(#/^\^a caret and \{braces\}$/#) { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then(#/^I open the path a\/#b$/#) { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then(#/^a data table$/#) { _, step in
            let dataTable = step.dataTable
            XCTFail("Step not implemented: replace this line with your test code")
        }
        Then(#/^a doc string$/#) { _, step in
            let docString = step.docString
            XCTFail("Step not implemented: replace this line with your test code")
        }
        // END GENERATED
    }
}
