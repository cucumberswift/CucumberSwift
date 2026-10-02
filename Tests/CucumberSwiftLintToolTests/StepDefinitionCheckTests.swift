@testable import CucumberSwiftLintTool
import XCTest

final class StepDefinitionCheckTests: LintTestCase {
    // MARK: Undefined steps

    func testAStepThatNoDefinitionMatchesIsUndefined() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given I have 42 cukes
            Then nothing matches this
        """, steps: #"Given("I have {int} cukes") { _, _ in }"#)
        XCTAssertEqual(messages, ["4:5 Undefined step: no step definition matches \"nothing matches this\""])
    }

    func testEachKindOfLiteralPatternIsMatched() throws {
        let messages = try lint("""
        Feature: F
          Background:
            Given a string pattern
          Scenario: S
            When an anchored pattern with 3 items
            Then a regex literal with 4 items
            And a bare slash regex literal
            But an optional word
        """, steps: """
        Given("a string pattern") { _, _ in }
        When("^an anchored pattern with (\\\\d+) items$") { _, _ in }
        Then(#/^a regex literal with (\\d+) items$/#) { _, _ in }
        And(/^a bare slash regex literal$/) { _, _ in }
        MatchAll("an optional( word)") { _, _ in }
        """)
        XCTAssertEqual(messages, [])
    }

    func testARegexLiteralCanContainAnEscapedDelimiter() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given I open a/#5
        """, steps: #"Given(#/^I open a\/#(\d+)$/#) { _, _ in }"#)
        XCTAssertEqual(messages, [])
    }

    func testACustomParameterTypeMatchesAnything() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given there are 3 flights from LAX
        """, steps: #"Given("there are {int} flights from {airport}" as CucumberExpression) { _, _ in }"#)
        XCTAssertEqual(messages, [])
    }

    func testAQuantifierInAnAnchoredPatternIsNotAParameter() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given aa
            Given aaa
        """, steps: #"Given("^a{2}$") { _, _ in }"#)
        XCTAssertEqual(messages, ["4:5 Undefined step: no step definition matches \"aaa\""])
    }

    func testOutlineStepsAreMatchedWithTheirExamples() throws {
        let messages = try lint("""
        Feature: F
          Scenario Outline: S
            Given a user named "<name>"
            Then the basket has <count> items

            Examples:
              | name  | count |
              | Alice | 1     |
        """, steps: """
        Given("a user named {string}") { _, _ in }
        Then("the basket has {int} items") { _, _ in }
        """)
        XCTAssertEqual(messages, [])
    }

    func testAnUndefinedOutlineStepIsReportedWithItsFirstExample() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given a user named <name>

            Examples:
              | name  |
              | Alice |
              | Bob   |
        """, steps: #"Given("a user called {word}") { _, _ in }"#)
        XCTAssertEqual(messages, ["3:5 Undefined step: no step definition matches \"a user named Alice\""])
    }

    func testWithoutStepDefinitionsNoStepIsReportedAsUndefined() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given anything at all
        """, steps: "// The step definitions are in another module.")
        XCTAssertEqual(messages, [])
    }

    func testAnInterpolatedPatternIsIgnored() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given a step
        """, steps: """
        Given("a step") { _, _ in }
        Given("\\(prefix) step") { _, _ in }
        """)
        XCTAssertEqual(messages, [])
    }

    // MARK: Step definitions that can never match

    func testAnInvalidAnchoredPatternIsReportedOnItsLine() throws {
        let steps = """
        Given("a step") { _, _ in }
        Then("^a broken (step$") { _, _ in }
        """
        let diagnostics = try check("Feature: F\n", steps: steps)
        XCTAssertEqual(diagnostics.map(\.line), [2])
        XCTAssertTrue(diagnostics.allSatisfy { $0.file.hasSuffix("Steps.swift") })
        XCTAssertTrue(diagnostics[0].message.hasPrefix("This step definition can never match"))
    }

    func testARegexLiteralThatDoesNotCompileIsReported() throws {
        let diagnostics = try check("Feature: F\n", steps: #"Then(#/^a broken (step$/#) { _, _ in }"#)
        XCTAssertEqual(diagnostics.map(\.line), [1])
        XCTAssertTrue(diagnostics[0].message.hasPrefix("This regular expression does not compile"))
    }
}
