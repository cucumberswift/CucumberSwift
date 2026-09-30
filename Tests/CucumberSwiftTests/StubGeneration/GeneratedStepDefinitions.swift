//
//  GeneratedStepDefinitions.swift
//  CucumberSwiftTests
//
// swiftlint:disable all

import Foundation
import CucumberSwift

/// The step definitions CucumberSwift generates for `feature`, pasted in unchanged, in the default
/// `#/…/#` style. Compiling this file proves the generated code compiles in a target without
/// bare slash regex literals (SwiftPM builds this one in the Swift 5 language mode), and
/// `GeneratedStepDefinitionTests` checks that the code still matches the generator's output and
/// that it matches and passes every step of `feature`.
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

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
    static func register() {
        // BEGIN GENERATED
        Given(#/^a step with no parameters$/#) { _, _ in

        }
        MatchAll(#/^a repeated step$/#) { _, _ in

        }
        When(#/^I log in as \"(.*?)\" with the password \"(.*?)\"$/#) { matches, _ in
            let string = matches.1
            let stringTwo = matches.2
        }
        Then(#/^I see (\d+) messages$/#) { matches, _ in
            let integer = matches.1
        }
        Given(#/^a step with \(brackets\), \[square brackets], a\/slash, a price of \$(\d+)\.(\d+)\? and a star\*$/#) { matches, _ in
            let integer = matches.1
            let integerTwo = matches.2
        }
        When(#/^I pay (\d+) to \"(.*?)\" and (\d+) to \"(.*?)\"$/#) { matches, _ in
            let integer = matches.1
            let string = matches.2
            let integerTwo = matches.3
            let stringTwo = matches.4
        }
        Then(#/^I open the path a\/#b$/#) { _, _ in

        }
        Then(#/^a data table$/#) { _, step in
            let dataTable = step.dataTable
        }
        Then(#/^a doc string$/#) { _, step in
            let docString = step.docString
        }
        // END GENERATED
    }
}
