//
//  MacroStepGenerationTests.swift
//  CucumberSwiftTests
//
//  The step definitions generated for undefined steps are step definition macros, as Convert to Gherkin
//  Macros writes them, when the test target links the macros, or Cucumber.generateMacros or
//  CUCUMBER_GENERATE_MACROS asks for them (#453). This bundle doesn't link them. GeneratedStepDefinitionTests
//  checks that they compile, and the StepDefinitionMacrosPackage fixture that they are its default.
//

import Foundation
import XCTest
@testable import CucumberSwift

class MacroStepGenerationTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
        addTeardownBlock {
            Cucumber.shared.reset()
            Cucumber.generateMacros = nil
            Cucumber.generateRegexLiterals = nil
            Cucumber.shared.environment["CUCUMBER_GENERATE_MACROS"] = nil
            Cucumber.overrideRegexLiteralStyle = .extendedDelimiter
        }
    }

    private func features(_ steps: String) -> [Feature] {
        Cucumber(withString: """
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
        \(steps)
        """).features
    }

    private func stubs(for steps: String) -> String {
        StubGenerator.getStubs(for: features(steps)).map(\.generatedSwift).joined(separator: "\n")
    }

    func testStepDefinitionsAreFunctionsWithoutTheMacrosLinked() {
        XCTAssertTrue(stubs(for: "Given I see 3 messages").hasPrefix(#"Given("I see {int} messages") { match, _ in"#))
    }

    func testTheFlagSwitchesToMacrosWithATypedArgumentPerParameter() {
        Cucumber.generateMacros = true
        XCTAssertEqual(stubs(for: #"Given I pay 5.25 to "Sue" and 6 to "Bob""#), #"""
        #Given("I pay {float} to {string} and {int} to {string}") { (float: Float, string: String, int: Int, stringTwo: String) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)
    }

    func testTheEnvironmentVariableSwitchesToMacros() {
        Cucumber.shared.environment["CUCUMBER_GENERATE_MACROS"] = "YES"
        XCTAssertTrue(stubs(for: "Given I log in").hasPrefix(#"#Given("I log in") {"#))

        Cucumber.generateMacros = false
        XCTAssertTrue(stubs(for: "Given I log in").hasPrefix(#"Given("I log in") { _, _ in"#))
    }

    func testAMacroTakesTheStepLastToReadADataTable() {
        Cucumber.generateMacros = true
        XCTAssertEqual(stubs(for: """
             Given I have 3 cukes:
               | a |
        """), #"""
        #Given("I have {int} cukes:") { (int: Int, step: Step) in
            let dataTable = step.dataTable
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)
    }

    // A step definition macro checks its Cucumber Expression as the specification reads it, which can't escape a `^`.
    func testAStepThatStartsWithACaretIsAnAnchoredRegularExpression() {
        Cucumber.generateMacros = true
        XCTAssertEqual(stubs(for: #"Given ^a caret and "text""#), #"""
        #Given("^\\^a caret and \\\"(.*?)\\\"$") { (string: String) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)

        Cucumber.generateMacros = false
        XCTAssertTrue(stubs(for: #"Given ^a caret and "text""#).hasPrefix(#"Given("\\^a caret and {string}")"#))
    }

    func testRegexLiteralMacrosTakeSubstrings() {
        Cucumber.generateMacros = true
        Cucumber.generateRegexLiterals = true
        XCTAssertEqual(stubs(for: "Given I see 3 messages"), #"""
        #Given(#/^I see (\d+) messages$/#) { (integer: Substring) in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)

        Cucumber.overrideRegexLiteralStyle = .bareSlash
        XCTAssertTrue(stubs(for: "Given I see 3 messages").hasPrefix(#"#Given(/^I see (\d+) messages$/) { (integer: Substring) in"#))
    }

    // The failure for an undefined step suggests the step definition `getStubs` lists for its pattern.
    func testTheFailureSuggestsAMacroForAStepWhoseStepDefinitionIsAnotherStepsMatchAll() throws {
        Cucumber.generateMacros = true
        let features = features("""
             Given I wait
             When I wait
        """)
        let step = try XCTUnwrap(features.first?.scenarios.first?.steps.last)

        XCTAssertEqual(StubGenerator.stub(for: step, in: features), #"""
        #MatchAll("I wait") {
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)
    }
}
