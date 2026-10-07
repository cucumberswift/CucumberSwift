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

    func testTheStepClassesAreStepDefinitions() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given I have 3 cukes
            When I eat 1
            Then I have 2 left
            And none are green
            But one is pickled
            * the rest are fresh
        """, steps: """
        GivenStep("I have {int} cukes") { _, _ in }
        WhenStep("I eat {int}") { _, _ in }
        ThenStep("I have {int} left") { _, _ in }
        AndStep("none are green") { _, _ in }
        ButStep("one is pickled") { _, _ in }
        MatchAllStep("the rest are fresh") { _, _ in }
        """)
        XCTAssertEqual(messages, [])
    }

    /// Both runners, XCTest and Swift Testing, declare the step classes and their English typealiases in StepDSL.swift.
    func testEveryStepClassAndTypealiasInTheRunnersIsRead() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let declaration = try NSRegularExpression(
            pattern: #"^public (?:final class (\w+): StepDSL\b|typealias (\w+) = \w+Step$)"#, options: .anchorsMatchLines)
        for file in ["CucumberSwift/DSL/StepDSL.swift", "CucumberSwiftTesting/StepDSL.swift"] {
            let source = try String(contentsOf: root.appendingPathComponent("Sources/\(file)"), encoding: .utf8)
            let names = declaration.matches(in: source, range: NSRange(source.startIndex..., in: source)).compactMap { match in
                (Range(match.range(at: 1), in: source) ?? Range(match.range(at: 2), in: source)).map { String(source[$0]) }
            }
            XCTAssertEqual(names.count, 12, file)
            XCTAssertEqual(Set(names).subtracting(StepDefinition.names), [], file)
        }
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

    func testEachExamplesBlockFillsInStepsWithItsOwnHeader() throws {
        let messages = try lint("""
        Feature: F
          Scenario Outline: S
            Given a user named <name> aged <age>

            Examples: adults
              | name  | age |
              | Alice | 30  |

            Examples: children, with the columns the other way round
              | age | name |
              | 7   | Bob  |
        """, steps: #"Given("a user named {word} aged {int}") { _, _ in }"#)
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

    // MARK: Comments

    func testACommentedOutStepDefinitionDoesNotDefineAStep() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given a step
            When I have cukes
            Then I had cukes
        """, steps: """
        Given("a step") { _, _ in }
        // Given("I have cukes") { _, _ in }
        /* Then("I had cukes") { _, _ in } */
        """)
        XCTAssertEqual(messages, [
            "4:5 Undefined step: no step definition matches \"I have cukes\"",
            "5:5 Undefined step: no step definition matches \"I had cukes\""
        ])
    }

    func testACommentedOutInvalidPatternIsNotReported() throws {
        let diagnostics = try check("Feature: F\n", steps: """
        // #Then("the basket holds {int} cukes$") { (count: Int) in }
        /// Then(#/^a broken (step$/#) { _, _ in }
        /*
         Then("^a broken (step$") { _, _ in }
         /* A nested comment. */
         Then(/^a broken (step$/) { _, _ in }
         */
        """)
        XCTAssertEqual(diagnostics.map(\.message), [])
    }

    func testAStepDefinitionAfterABlockCommentOnTheSameLineIsRead() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given a step
            Then another step
        """, steps: """
        /* An old version. */ Given("a step") { _, _ in }
        /* An /* old */ version. */ Then("another step") { _, _ in }
        """)
        XCTAssertEqual(messages, [])
    }

    func testCommentDelimitersInAPatternAreNotAComment() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given I open http://example.com
            When I visit https://example.com
            Then I see a /* b
            And I see c */ d
            But I go to x//y
        """, steps: #"""
        Given("^I open http://example\\.com$") { _, _ in }
        When(#/^I visit https?://[a-z.]+$/#) { _, _ in }
        Then("^I see a /\\* b$") { _, _ in }
        And("^I see c \\*/ d$") { _, _ in }
        But(/^I go to x\/\/y$/) { _, _ in }
        """#)
        XCTAssertEqual(messages, [])
    }

    func testCommentDelimitersInOtherLiteralsAreNotAComment() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given a step
            Then another step
        """, steps: #"""
        let raw = #"a "/*" b"#
        let interpolated = "\(flag ? "/*" : "")"
        let multiLine = """
            /*
            """
        Given("a step") { _, _ in }
        let regex = #/a /* b/#
        Then("another step") { _, _ in }
        """#)
        XCTAssertEqual(messages, [])
    }

    func testAnInvalidPatternAfterACommentIsReportedOnItsOwnLine() throws {
        let diagnostics = try check("Feature: F\n", steps: """
        /*
         A comment over
         three lines. */
        let url = "http://example.com" // A comment.
        Then("^a broken (step$") { _, _ in }
        """)
        XCTAssertEqual(diagnostics.map(\.line), [5])
    }
}
