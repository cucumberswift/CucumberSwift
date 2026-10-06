@testable import CucumberSwiftLintTool
import XCTest

// swiftlint:disable:next type_body_length
final class FeatureFixerTests: LintTestCase {
    /// Writes `feature`, fixes it, and returns the file's new text and each change as
    /// "line: before → after".
    func fix(_ feature: String) throws -> (text: String, changes: [String]) {
        let file = directory.appendingPathComponent("Test.feature")
        try feature.write(to: file, atomically: true, encoding: .utf8)
        let changes = try FeatureFixer.fix(file: file.path).map { "\($0.line): \($0.before) → \($0.after)" }
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
            Then another step
        """)
        XCTAssertEqual(result.changes, ["3: Gvien a step → Given a step"])
    }

    func testAKeywordInTheWrongCaseIsFixed() throws {
        let result = try fix("""
        feature: F
          Scenario: S
            Given a step
            then another step
        """)
        XCTAssertEqual(result.changes, ["1: feature: F → Feature: F", "4: then another step → Then another step"])
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

    func testAMisspeltHeaderOfMoreThanOneWordIsReplacedWhole() throws {
        let result = try fix("""
        Feature: Basket

          Scenaro Outline: Eat <n> cukes
            Given I have <n> cukes

            Examples:
              | n |
              | 3 |

          Scenario Outlne: Eat <n> more cukes
            Given I have <n> cukes

            Examples:
              | n |
              | 4 |

          Scenaro Template Eat <n> cukes again
            Given I have <n> cukes
        """)
        XCTAssertEqual(result.changes, [
            "3: Scenaro Outline: Eat <n> cukes → Scenario Outline: Eat <n> cukes",
            "10: Scenario Outlne: Eat <n> more cukes → Scenario Outline: Eat <n> more cukes",
            "17: Scenaro Template Eat <n> cukes again → Scenario Template: Eat <n> cukes again"
        ])
        XCTAssertEqual(result.text, """
        Feature: Basket

          Scenario Outline: Eat <n> cukes
            Given I have <n> cukes

            Examples:
              | n |
              | 3 |

          Scenario Outline: Eat <n> more cukes
            Given I have <n> cukes

            Examples:
              | n |
              | 4 |

          Scenario Template: Eat <n> cukes again
            Given I have <n> cukes
        """)
    }

    func testAnotherHeaderIsNotReplacedByAHeaderOfMoreThanOneWord() throws {
        // "Scenarios" is one edit from "Scenario", but is a header itself.
        let result = try fix("""
        Feature: F
          Scenario Outline: O <a>
            Given a <a>
            Scenarios Outline
              | a |
              | b |
        """)
        XCTAssertEqual(result.changes, ["4: Scenarios Outline → Scenarios: Outline"])
    }

    func testACorrectHeaderOfMoreThanOneWordIsNotChanged() throws {
        let feature = """
        Feature: F
          Scenario Outline: Eat <n> cukes
            Given I have <n> cukes
            Examples:
              | n |
              | 3 |
          Scenario Template: Eat <n> more cukes
            Given I have <n> cukes
            Examples:
              | n |
              | 4 |
        """
        let result = try fix(feature)
        XCTAssertEqual(result.changes, [])
        XCTAssertEqual(result.text, feature)
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

        XCTAssertEqual(try FeatureFixer.fix(file: file.path), [])
        XCTAssertEqual(try Data(contentsOf: file), original)
        let modified = try FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
        XCTAssertEqual(modified, past)
    }

    func testOnlyTheFixedWordChanges() throws {
        let file = directory.appendingPathComponent("Test.feature")
        let original = Data([0xEF, 0xBB, 0xBF]) + Data("Feature: F\r\n  Scenario: S\r\n\tGiven a step\r\n\tThne a step  \r\n".utf8)
        try original.write(to: file)

        XCTAssertEqual(try FeatureFixer.fix(file: file.path).map(\.after), ["Then a step"])
        let expected = Data([0xEF, 0xBB, 0xBF]) + Data("Feature: F\r\n  Scenario: S\r\n\tGiven a step\r\n\tThen a step  \r\n".utf8)
        XCTAssertEqual(try Data(contentsOf: file), expected)
    }

    func testDescriptionsAreNotChanged() throws {
        // Each line could be a mistake, but text after a header and before a step is a description.
        let feature = """
        Feature: F
          feature descriptions explain the goal
          Background information is below
          Features include signing in
          Scenario where the user is offline
          Example of a login

          Scenario: S
            and this is what it is about
            Given a step

          Scenario: T
            Gvien a step on its own
        """
        let result = try fix(feature)
        XCTAssertEqual(result.changes, [])
        XCTAssertEqual(result.text, feature)
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

    func testAFileThatCantBeSavedIsAnError() throws {
        try XCTSkipIf(getuid() == 0, "File permissions aren't enforced for root")
        let file = directory.appendingPathComponent("Test.feature")
        try "Feature: F\n  Scenario: S\n    Given a step\n    Thne another step\n".write(to: file, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: file.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path) }

        XCTAssertThrowsError(try FeatureFixer.fix(file: file.path)) { error in
            XCTAssertEqual((error as? FeatureFixer.Failure)?.file, file.path)
        }
        let result = FeatureFixer.fix(paths: [directory.path])
        XCTAssertEqual(result.changes, [])
        XCTAssertEqual(result.failures.map(\.file), [file.standardizedFileURL.path])
        XCTAssertTrue(try String(contentsOf: file, encoding: .utf8).contains("Thne"))
    }

    func testAFileThatCantBeReadIsAnError() throws {
        try XCTSkipIf(getuid() == 0, "File permissions aren't enforced for root")
        let unreadable = directory.appendingPathComponent("Unreadable.feature")
        try "Feature: F\n".write(to: unreadable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: unreadable.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: unreadable.path) }

        XCTAssertEqual(FeatureFixer.fix(paths: [directory.path]).failures, [
            .init(file: unreadable.standardizedFileURL.path, reason: "Couldn't read this feature file")
        ])
    }

    func testAFileThatIsntUTF8IsAnError() throws {
        let latin1 = directory.appendingPathComponent("Latin1.feature")
        // "Café" in Latin-1, where "é" is the single byte E9.
        try (Data("Feature: Caf".utf8) + Data([0xE9, 0x0A])).write(to: latin1)

        XCTAssertEqual(FeatureFixer.fix(paths: [directory.path]).failures, [
            .init(file: latin1.standardizedFileURL.path, reason: "This feature file isn't UTF-8 text, so it wasn't checked")
        ])
    }

    func testAMissingPathIsAnError() {
        let missing = directory.appendingPathComponent("Missing.feature").path
        XCTAssertEqual(FeatureFixer.fix(paths: [missing]).failures, [.init(file: missing, reason: "No such feature file or folder")])
    }

    func testTheExitStatusIsOneWhenAnythingFails() throws {
        try "Feature: F\n  Scenario: S\n    Given a step\n    Thne another step\n"
            .write(to: directory.appendingPathComponent("A.feature"), atomically: true, encoding: .utf8)
        var output = [String]()
        var errors = [String]()
        let missing = directory.appendingPathComponent("Missing.feature").path

        XCTAssertEqual(FeatureFixer.run(paths: [directory.path], output: { output.append($0) }, errorOutput: { errors.append($0) }), 0)
        XCTAssertEqual(output.last, "Fixed 1 line in 1 of 1 feature file.")
        XCTAssertEqual(errors, [])

        output = []
        XCTAssertEqual(FeatureFixer.run(paths: [directory.path, missing], output: { output.append($0) }, errorOutput: { errors.append($0) }), 1)
        XCTAssertEqual(output, ["Fixed nothing."])
        XCTAssertEqual(errors, ["\(missing): error: No such feature file or folder"])
    }

    // MARK: Agreement with the build plugin

    func testEveryFixIsAWarningsSuggestion() throws {
        // A suggestion for a line that could be a description is still reported, but not fixed.
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
        for diagnostic in fixes {
            XCTAssertTrue(diagnostic.message.contains("Did you mean"), diagnostic.message)
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

        let found = FeatureFixer.featureFiles(in: [directory.path, directory.appendingPathComponent("C.feature").path]).files
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
