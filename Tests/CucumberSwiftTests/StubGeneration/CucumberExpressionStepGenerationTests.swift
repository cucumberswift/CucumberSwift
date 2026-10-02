//
//  CucumberExpressionStepGenerationTests.swift
//  CucumberSwiftTests
//
//  The step definitions generated for undefined steps are Cucumber Expressions with typed parameters,
//  unless Cucumber.generateRegexLiterals or CUCUMBER_GENERATE_REGEX_LITERALS asks for regex literals (#263).
//

import Foundation
import XCTest
import CucumberSwiftExpressions
@testable import CucumberSwift

class CucumberExpressionStepGenerationTests: XCTestCase {
    override func setUpWithError() throws {
        Cucumber.shared.reset()
        addTeardownBlock {
            Cucumber.shared.reset()
            Cucumber.generateRegexLiterals = nil
            Cucumber.shared.environment["CUCUMBER_GENERATE_REGEX_LITERALS"] = nil
            Cucumber.overrideRegexLiteralStyle = .extendedDelimiter
        }
    }

    private func stubs(for steps: String, style: StubGenerator.Style = StubGenerator.implementorStyle) -> String {
        StubGenerator.getStubs(for: Cucumber(withString: """
        Feature: Some terse yet descriptive text of what is desired
           Scenario: Some determinable business situation
        \(steps)
        """).features, style: style)
            .map(\.generatedSwift)
            .joined(separator: "\n")
    }

    func testStepDefinitionsAreCucumberExpressionsByDefault() {
        XCTAssertEqual(stubs(for: "Given I see 3 messages"), #"""
        Given("I see {int} messages") { match, _ in
            let int = try match.first(\.int)
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)
    }

    func testRegexLiteralStyleAloneDoesNotSwitchToRegexLiterals() {
        Cucumber.overrideRegexLiteralStyle = .bareSlash
        XCTAssertEqual(stubs(for: "Given Some precondition"), #"""
        Given("Some precondition") { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)
    }

    func testTheFlagSwitchesToRegexLiteralsInTheStepImplementationsStyle() {
        Cucumber.generateRegexLiterals = true
        XCTAssertTrue(stubs(for: "Given Some precondition").hasPrefix("Given(#/^Some precondition$/#)"))

        Cucumber.overrideRegexLiteralStyle = .bareSlash
        XCTAssertTrue(stubs(for: "Given Some precondition").hasPrefix("Given(/^Some precondition$/)"))
    }

    func testTheEnvironmentVariableSwitchesToRegexLiterals() {
        Cucumber.shared.environment["CUCUMBER_GENERATE_REGEX_LITERALS"] = "YES"
        XCTAssertTrue(stubs(for: "Given Some precondition").hasPrefix("Given(#/^Some precondition$/#)"))

        Cucumber.generateRegexLiterals = false
        XCTAssertTrue(stubs(for: "Given Some precondition").hasPrefix(#"Given("Some precondition")"#))
    }

    func testAParameterTypeThatAppearsMoreThanOnceIsReadByIndex() {
        XCTAssertEqual(stubs(for: #"Given I pay 5 to "Sue" and 6 to "Bob" for "lunch""#), #"""
        Given("I pay {int} to {string} and {int} to {string} for {string}") { match, _ in
            let int = match[\.int, index: 0]
            let string = match[\.string, index: 0]
            let intTwo = match[\.int, index: 1]
            let stringTwo = match[\.string, index: 1]
            let stringThree = match[\.string, index: 2]
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)
    }

    func testADecimalIsAFloatAndASignBelongsToItsNumber() {
        XCTAssertEqual(stubs(for: "Given it is -3.5 degrees at -2 and a-1 is 7. Done"), #"""
        Given("it is {float} degrees at {int} and a-{int} is {int}. Done") { match, _ in
            let float = try match.first(\.float)
            let int = match[\.int, index: 0]
            let intTwo = match[\.int, index: 1]
            let intThree = match[\.int, index: 2]
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)
    }

    func testStepsThatDifferOnlyInTheirNumbersShareAStepDefinition() {
        XCTAssertEqual(stubs(for: """
             Given I see 5 messages
             And I see -5 messages
        """), #"""
        Given("I see {int} messages") { match, _ in
            let int = try match.first(\.int)
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)
    }

    func testCharactersThatMeanSomethingInACucumberExpressionAreEscaped() {
        XCTAssertEqual(stubs(for: #"Given ^a (step) with {braces}, a/slash and a \backslash"#), #"""
        Given("\\^a \\(step) with \\{braces}, a\\/slash and a \\\\backslash") { _, _ in
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)
    }

    func testAStepThatEndsInADollarSignIsAnAnchoredRegularExpression() {
        XCTAssertEqual(stubs(for: #"Given "Sue" owes 5$"#), #"""
        Given("^\\\"(.*?)\\\" owes (\\d+)\\$$") { match, _ in
            let string = match[\.anonymous, index: 0]
            let stringTwo = match[\.anonymous, index: 1]
            XCTFail("Step not implemented: replace this line with your test code")
        }
        """#)
    }

    // The generated patterns above, as Swift reads them, match their steps and read the right values.
    func testTheGeneratedPatternsReadTheValuesOfTheirSteps() throws {
        let temperature = try XCTUnwrap(CucumberExpression("it is {float} degrees at {int} and a-{int} is {int}. Done")
            .match(in: "it is -3.5 degrees at -2 and a-1 is 7. Done"))
        XCTAssertEqual(try temperature.first(\.float), -3.5)
        XCTAssertEqual(try temperature.allParameters(\.int), [-2, 1, 7])

        let payment = try XCTUnwrap(CucumberExpression("I pay {int} to {string} and {int} to {string} for {string}")
            .match(in: #"I pay 5 to "Sue" and 6 to "Bob" for "lunch""#))
        XCTAssertEqual(try payment.allParameters(\.int), [5, 6])
        XCTAssertEqual(try payment.allParameters(\.string), ["Sue", "Bob", "lunch"])

        XCTAssertNotNil(CucumberExpression(#"\^a \(step) with \{braces}, a\/slash and a \\backslash"#)
            .match(in: #"^a (step) with {braces}, a/slash and a \backslash"#))

        let debt = try XCTUnwrap(CucumberExpression(#"^\"(.*?)\" owes (\d+)\$$"#).match(in: #""Sue" owes 5$"#))
        XCTAssertEqual(debt[\.anonymous, index: 0], "Sue")
        XCTAssertEqual(debt[\.anonymous, index: 1], "5")
    }
}
