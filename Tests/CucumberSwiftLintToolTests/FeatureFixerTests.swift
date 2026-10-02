@testable import CucumberSwiftLintTool
import XCTest

final class FeatureFixerTests: LintTestCase {
    /// Writes `feature`, fixes it, and returns the file's new text and each change as
    /// "line: before → after".
    func fix(_ feature: String) throws -> (text: String, changes: [String]) {
        let file = directory.appendingPathComponent("Test.feature")
        try feature.write(to: file, atomically: true, encoding: .utf8)
        let changes = FeatureFixer.fix(file: file.path).map { "\($0.line): \($0.before) → \($0.after)" }
        return (try String(contentsOf: file, encoding: .utf8), changes)
    }

    // MARK: Each kind of fix

    func testAMisspeltStepKeywordIsFixed() throws {
        let result = try fix("""
        Feature: F
          Scenario: S
            Given a step
            Thne another step
        """)
        XCTAssertEqual(result.changes, ["4: Thne another step → Then another step"])
        XCTAssertEqual(result.text, """
        Feature: F
          Scenario: S
            Given a step
            Then another step
        """)
    }

    func testAMisspeltFirstStepIsFixed() throws {
        let result = try fix("""
        Feature: F
          Scenario: S
            Gvien a step
        """)
        XCTAssertEqual(result.changes, ["3: Gvien a step → Given a step"])
    }

    func testAKeywordInTheWrongCaseIsFixed() throws {
        let result = try fix("""
        Feature: F
          Scenario: S
            given a step
        """)
        XCTAssertEqual(result.changes, ["3: given a step → Given a step"])
    }

    func testAHeaderWithoutItsColonIsFixed() throws {
        let result = try fix("""
        Feature: F
          Scenario S
            Given a step
          Scenario Outline O
            Given a step
            Examples
              | a |
        """)
        XCTAssertEqual(result.changes, [
            "2: Scenario S → Scenario: S",
            "4: Scenario Outline O → Scenario Outline: O",
            "6: Examples → Examples:"
        ])
    }

    func testAMisspeltHeaderKeepsItsColon() throws {
        let result = try fix("""
        Feture: F
          scenario outline: S
            Given a <thing>
            Examples:
              | thing |
              | step  |
          Scenaro: T
            Given a step
        """)
        XCTAssertEqual(result.changes, [
            "1: Feture: F → Feature: F",
            "2: scenario outline: S → Scenario Outline: S",
            "7: Scenaro: T → Scenario: T"
        ])
    }

    func testAFixThatRevealsAnotherIsFollowedByIt() throws {
        // "Adn" is too short to be reported until the lines before it are steps.
        let result = try fix("""
        Feature: F
          Scenario: S
            Gvien a step
            Adn another step
        """)
        XCTAssertEqual(result.changes, ["3: Gvien a step → Given a step", "4: Adn another step → And another step"])
    }

    // MARK: What is left alone

    func testAFileWithNothingToFixIsNotWritten() throws {
        let file = directory.appendingPathComponent("Test.feature")
        // A byte order mark, Windows line endings, and warnings that have no fix.
        let original = Data([0xEF, 0xBB, 0xBF]) + Data("""
        Feature: F\r
          Scenario: S\r
            Given a table\r
              | a | b |\r
              | c |\r
            Then they went home\r

        """.utf8)
        try original.write(to: file)
        let past = Date(timeIntervalSince1970: 1_000_000_000)
        try FileManager.default.setAttributes([.modificationDate: past], ofItemAtPath: file.path)

        XCTAssertEqual(FeatureFixer.fix(file: file.path), [])
        XCTAssertEqual(try Data(contentsOf: file), original)
        let modified = try FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
        XCTAssertEqual(modified, past)
    }

    func testOnlyTheFixedWordChanges() throws {
        let file = directory.appendingPathComponent("Test.feature")
        let original = Data([0xEF, 0xBB, 0xBF]) + Data("Feature: F\r\n  Scenario: S\r\n\tThne a step  \r\n".utf8)
        try original.write(to: file)

        XCTAssertEqual(FeatureFixer.fix(file: file.path).map(\.after), ["Then a step"])
        let expected = Data([0xEF, 0xBB, 0xBF]) + Data("Feature: F\r\n  Scenario: S\r\n\tThen a step  \r\n".utf8)
        XCTAssertEqual(try Data(contentsOf: file), expected)
    }

    func testDocStringsAndOtherLanguagesAreNotChanged() throws {
        let docString = """
        Feature: F
          Scenario: S
            Given a doc string
              ```
              Thne this is not a step
              ```
        """
        XCTAssertEqual(try fix(docString).changes, [])
        XCTAssertEqual(try fix(docString).text, docString)

        let french = """
        # language: fr
        Fonctionnalité: F
          Scénario: S
            Soit une étape
        """
        XCTAssertEqual(try fix(french).changes, [])
        XCTAssertEqual(try fix(french).text, french)
    }

    // MARK: Agreement with the build plugin

    func testEveryFixIsAWarningsSuggestion() throws {
        let diagnostics = try check("""
        Feature: F
          Scenario S
            Gvien a step
            Then a table
              | a | b |
              | c |
            Thne another step
            Not a keyword
        """, steps: nil)
        let fixes = diagnostics.filter { $0.fix != nil }
        XCTAssertEqual(fixes.map(\.line), [2, 3, 7])
        for diagnostic in diagnostics {
            XCTAssertEqual(diagnostic.fix != nil, diagnostic.message.contains("Did you mean"), diagnostic.message)
        }
        XCTAssertEqual(fixes.compactMap(\.fix), [
            .init(text: "Scenario", replacement: "Scenario:"),
            .init(text: "Gvien", replacement: "Given"),
            .init(text: "Thne", replacement: "Then")
        ])
    }

    // MARK: Finding feature files

    func testFeatureFilesAreFoundInFoldersButNotHiddenOnes() throws {
        let features = directory.appendingPathComponent("Features/Nested")
        let build = directory.appendingPathComponent(".build/checkouts")
        try FileManager.default.createDirectory(at: features, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: build, withIntermediateDirectories: true)
        let files = [
            features.appendingPathComponent("A.feature"),
            features.appendingPathComponent("Steps.swift"),
            build.appendingPathComponent("B.feature"),
            directory.appendingPathComponent("C.feature")
        ]
        for file in files {
            try Data().write(to: file)
        }

        let found = FeatureFixer.featureFiles(in: [directory.path, directory.appendingPathComponent("C.feature").path])
        XCTAssertEqual(found.map { URL(fileURLWithPath: $0).lastPathComponent }, ["C.feature", "A.feature"])
    }

    func testFixPathsAreReadFromTheCommandLine() {
        let arguments = Arguments(["--fix", "Features", "A.feature"])
        XCTAssertTrue(arguments.fix)
        XCTAssertEqual(arguments.fixPaths, ["Features", "A.feature"])
        XCTAssertTrue(Arguments(["--fix"]).fix)
        XCTAssertFalse(Arguments(["--features", "A.feature"]).fix)
    }
}
