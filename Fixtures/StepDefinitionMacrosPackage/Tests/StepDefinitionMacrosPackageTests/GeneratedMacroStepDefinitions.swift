//
//  GeneratedMacroStepDefinitions.swift
//  StepDefinitionMacrosPackageTests
//
// swiftlint:disable all

@testable import CucumberSwift
import CucumberSwiftMacros
import Foundation
import XCTest

/// The step definition macros CucumberSwift generates, its default in a target that links the macros,
/// for the feature in CucumberSwiftTests' `GeneratedStepDefinitions.swift`, pasted in unchanged: with
/// Cucumber Expressions, with `#/…/#` regex literals and with `/…/` regex literals, which this Swift 6
/// target accepts. Compiling this file proves the macros expand and their closures fit their patterns.
/// CucumberSwiftTests' `GeneratedStepDefinitionTests` checks that it still matches the generator.
/// Nothing calls these functions. `SuggestedStepDefinitionTests` below checks that macros are the default.
///
/// If the generator changes, replace everything between the BEGIN and END lines with the output
/// the failing test prints.
enum GeneratedMacroStepDefinitions {
    static func registerCucumberExpressions() {
        // BEGIN GENERATED CUCUMBER EXPRESSION MACROS
        #Given("a step with no parameters") {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #MatchAll("a repeated step") {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #When("I log in as {string} with the password {string}") { (string: String, stringTwo: String) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then("I see {int} messages") { (int: Int) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Given("a step with \\(brackets), [square brackets], a\\/slash, a price of ${float}? and a star*") { (float: Float) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #When("I pay {int} to {string} and {int} to {string}") { (int: Int, string: String, intTwo: Int, stringTwo: String) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then("the temperature is {int} degrees") { (int: Int) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then("^I owe (\\d+)\\$$") { (string: String) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then("^\\^a caret and \\{braces\\}$") {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then("I open the path a\\/#b") {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then("a data table") { (step: Step) in
            let dataTable = step.dataTable
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then("a doc string") { (step: Step) in
            let docString = step.docString
            XCTFail("Step not implemented: replace this line with your test code")
        }
        // END GENERATED CUCUMBER EXPRESSION MACROS
    }

    static func registerExtendedDelimiterRegexLiterals() {
        // BEGIN GENERATED EXTENDED DELIMITER MACROS
        #Given(#/^a step with no parameters$/#) {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #MatchAll(#/^a repeated step$/#) {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #When(#/^I log in as \"(.*?)\" with the password \"(.*?)\"$/#) { (string: Substring, stringTwo: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(#/^I see (\d+) messages$/#) { (integer: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Given(#/^a step with \(brackets\), \[square brackets], a\/slash, a price of \$(\d+)\.(\d+)\? and a star\*$/#) { (integer: Substring, integerTwo: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #When(#/^I pay (\d+) to \"(.*?)\" and (\d+) to \"(.*?)\"$/#) { (integer: Substring, string: Substring, integerTwo: Substring, stringTwo: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(#/^the temperature is -(\d+) degrees$/#) { (integer: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(#/^I owe (\d+)\$$/#) { (integer: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(#/^\^a caret and \{braces\}$/#) {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(#/^I open the path a\/#b$/#) {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(#/^a data table$/#) { (step: Step) in
            let dataTable = step.dataTable
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(#/^a doc string$/#) { (step: Step) in
            let docString = step.docString
            XCTFail("Step not implemented: replace this line with your test code")
        }
        // END GENERATED EXTENDED DELIMITER MACROS
    }

    static func registerBareSlashRegexLiterals() {
        // BEGIN GENERATED BARE SLASH MACROS
        #Given(/^a step with no parameters$/) {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #MatchAll(/^a repeated step$/) {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #When(/^I log in as \"(.*?)\" with the password \"(.*?)\"$/) { (string: Substring, stringTwo: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(/^I see (\d+) messages$/) { (integer: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Given(/^a step with \(brackets\), \[square brackets], a\/slash, a price of \$(\d+)\.(\d+)\? and a star\*$/) { (integer: Substring, integerTwo: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #When(/^I pay (\d+) to \"(.*?)\" and (\d+) to \"(.*?)\"$/) { (integer: Substring, string: Substring, integerTwo: Substring, stringTwo: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(/^the temperature is -(\d+) degrees$/) { (integer: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(/^I owe (\d+)\$$/) { (integer: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(/^\^a caret and \{braces\}$/) {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(/^I open the path a\/#b$/) {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(/^a data table$/) { (step: Step) in
            let dataTable = step.dataTable
            XCTFail("Step not implemented: replace this line with your test code")
        }
        #Then(/^a doc string$/) { (step: Step) in
            let docString = step.docString
            XCTFail("Step not implemented: replace this line with your test code")
        }
        // END GENERATED BARE SLASH MACROS
    }
}

/// This target links the macros, so CucumberSwift suggests macros for undefined steps unless
/// `Cucumber.generateMacros` says otherwise.
final class SuggestedStepDefinitionTests: XCTestCase {
    override func tearDown() {
        Cucumber.generateMacros = nil
    }

    private func suggestion() -> String {
        let features = Cucumber(withString: """
        Feature: Suggestions
          Scenario: An undefined step
            Given I have 3 cukes
        """).features
        return StubGenerator.getStubs(for: features).map(\.generatedSwift).joined(separator: "\n")
    }

    func testAnUndefinedStepIsSuggestedAsAMacro() {
        XCTAssertEqual(suggestion(), """
        #Given("I have {int} cukes") { (int: Int) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """)
    }

    func testGenerateMacrosOffSuggestsAFunction() {
        Cucumber.generateMacros = false
        XCTAssertTrue(suggestion().hasPrefix(#"Given("I have {int} cukes") { match, _ in"#), suggestion())
    }
}
