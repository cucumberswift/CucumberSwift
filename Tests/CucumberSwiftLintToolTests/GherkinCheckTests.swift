@testable import CucumberSwiftLintTool
import XCTest

final class GherkinCheckTests: LintTestCase {
    // MARK: Gherkin

    func testAMisspeltStepKeywordIsReported() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given a step
            Thne another step
        """)
        XCTAssertEqual(messages, ["4:5 Expected a step (Given, When, Then, And, But), a table or a doc string. Did you mean 'Then'?"])
    }

    func testAMisspeltFirstStepIsReported() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Gvien a step
        """)
        XCTAssertEqual(messages, ["3:5 'Gvien' is not a Gherkin keyword. Did you mean 'Given'?"])
    }

    func testAHeaderWithoutItsColonIsReported() throws {
        let messages = try lint("""
        Feature: F
          Scenario S
            Given a step
        """)
        XCTAssertEqual(messages, ["2:3 'Scenario' is not a Gherkin keyword. Did you mean 'Scenario:'?"])
    }

    func testAMisspeltHeaderOfMoreThanOneWordIsReportedWhole() throws {
        let messages = try lint("""
        Feature: F
          Scenario Outlne: A <n>
            Given a step
          Scenaro Outline: B <n>
            Given a step
          Scenaro Template C <n>
            Given a step
        """)
        XCTAssertEqual(messages, [
            "2:3 'Scenario Outlne' is not a Gherkin keyword. Did you mean 'Scenario Outline:'?",
            "4:3 Expected a step (Given, When, Then, And, But), a table or a doc string. Did you mean 'Scenario Outline:'?",
            "6:3 Expected a step (Given, When, Then, And, But), a table or a doc string. Did you mean 'Scenario Template:'?"
        ])
    }

    func testAnotherHeaderIsNotReportedAsAHeaderOfMoreThanOneWord() throws {
        let messages = try lint("""
        Feature: F
          Scenario Outline: O <a>
            Given a <a>
            Scenarios Outline
              | a |
              | b |
        """)
        XCTAssertEqual(messages, ["4:5 Expected a step (Given, When, Then, And, But), a table or a doc string. Did you mean 'Scenarios:'?"])
    }

    func testACorrectHeaderOfMoreThanOneWordIsNotReported() throws {
        let messages = try lint("""
        Feature: F
          Scenario Outline: A <n>
            Given a step
            Examples:
              | n |
              | 1 |
          Scenario Template: B <n>
            Given a step
            Examples:
              | n |
              | 2 |
        """)
        XCTAssertEqual(messages, [])
    }

    func testDescriptionsAreAllowed() throws {
        let messages = try lint("""
        Feature: F
          They said this feature needs a description.
          Background:
            An example of a background description.
            Given a step
          Scenario: S
            Then nothing is wrong with this
            Given a step
          Scenario Outline: O
            Given a step
            Examples: E
              This is an examples description
              | a |
              | b |
        """)
        XCTAssertEqual(messages, [])
    }

    func testARowWithTheWrongNumberOfCellsIsReported() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given a table
              | a | b |
              | c | d | e |
              | f \\| g | h |
        """)
        XCTAssertEqual(messages, ["5:7 This row has 3 cells, but the table's first row (line 4) has 2"])
    }

    func testATableMustFollowAStep() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            | a |
        """)
        XCTAssertEqual(messages, ["3:5 A table must follow a step or an Examples line"])
    }

    func testAnUnclosedDocStringIsReported() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given a doc string
              ```
              Thne this is not checked
        """)
        XCTAssertEqual(messages, ["4:1 This doc string is never closed"])
    }

    func testAStepOutsideAScenarioIsReported() throws {
        let messages = try lint("""
        Feature: F
          Given a step
        """)
        XCTAssertEqual(messages, ["2:3 A step must be inside a Scenario or Background"])
    }

    func testAStepAfterExamplesIsReportedOnlyOnce() throws {
        let messages = try lint("""
        Feature: F
          Scenario Outline: S
            Given a user named <name>
            Examples:
              | name  |
              | Alice |
            Then the user is <name>
        """, steps: #"Given("a user named {word}") { _, _ in }"#)
        XCTAssertEqual(messages, ["7:5 A step can't follow Examples; start a new Scenario"])
    }

    func testExamplesUnderABackgroundAreReported() throws {
        let messages = try lint("""
        Feature: F
          Background:
            Given a step
          Examples:
            | a |
        """)
        XCTAssertEqual(messages, ["4:3 Examples belong to a Scenario Outline"])
    }

    func testKeywordsAreNotCheckedInAnotherLanguage() throws {
        let messages = try lint("""
        # language: fr
        Fonctionnalité: F
          Scénario: S
            Soit une étape
        """)
        XCTAssertEqual(messages, [])
    }

    func testTheRepositorysValidFeatureFilesHaveNoWarnings() throws {
        let good = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CucumberSwiftTests/testdata/good")
        let features = try XCTUnwrap(FileManager.default.enumerator(atPath: good.path))
            .compactMap { $0 as? String }
            .filter { $0.hasSuffix(".feature") }
            .map { good.appendingPathComponent($0).path }
        XCTAssertGreaterThan(features.count, 10)
        let diagnostics = Linter.check(features: features, stepDefinitionFiles: [])
        XCTAssertEqual(diagnostics.map(\.description), [])
    }

    // MARK: Command line

    func testAFileWhosePathStartsWithDashesIsStillAFile() {
        let arguments = Arguments(["--features", "--draft.feature", "b.feature", "--step-definitions", "Steps.swift"])
        XCTAssertEqual(arguments.features, ["--draft.feature", "b.feature"])
        XCTAssertEqual(arguments.swiftFiles, ["Steps.swift"])
    }

    func testArgumentsAreReadByOption() {
        let arguments = Arguments([
            "--stamp", "s", "--features", "a.feature", "b.feature", "--step-definitions", "Steps.swift"
        ])
        XCTAssertEqual(arguments.stamp, "s")
        XCTAssertEqual(arguments.features, ["a.feature", "b.feature"])
        XCTAssertEqual(arguments.swiftFiles, ["Steps.swift"])
    }

    func testADiagnosticIsPrintedAsAnXcodeWarning() {
        let diagnostic = Diagnostic(file: "/a/F.feature", line: 3, column: 5, message: "Oops")
        XCTAssertEqual(diagnostic.description, "/a/F.feature:3:5: warning: Oops")
    }

    func testLineNumbersAreFoundFromOffsets() {
        let starts = "a\nbc\n\nd".lineStartOffsets
        XCTAssertEqual(starts, [0, 2, 5, 6])
        XCTAssertEqual([0, 1, 2, 4, 5, 6].map { starts.line(containing: $0) }, [1, 1, 2, 2, 3, 4])
    }
}
