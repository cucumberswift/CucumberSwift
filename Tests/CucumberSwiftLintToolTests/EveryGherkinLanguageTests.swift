@testable import CucumberSwiftLintTool
import CucumberSwiftGherkin
import Foundation
import XCTest

/// Checks CucumberSwiftLint and Fix Feature Files in every language of the Gherkin language data that
/// CucumberSwift reads, `Sources/CucumberSwift/Gherkin/Core/Languages.swift`. Each test builds valid
/// feature files from that data, with every form of every keyword, so a language or a keyword added
/// to it later is tested without a change here.
final class EveryGherkinLanguageTests: LintTestCase {
    /// One language of the language data: its code, and the forms of each of its keywords.
    struct Language {
        let code: String
        let keywords: [String: [String]]

        func forms(_ key: String) -> [String] { keywords[key] ?? [] }
    }

    /// A feature file built for a language, and the lines a test changes to make a mistake.
    struct GeneratedFeature {
        let language: String
        var lines: [String]
        /// The first row of the table with two cells, and the row after it.
        let tableHeader: Int
        let tableRow: Int
        /// The line after the Feature line, where a step is out of place.
        let afterFeature: Int
        /// The closing delimiter of the doc string.
        let docStringEnd: Int
        /// A step keyword of the language, as written before a step's text.
        let stepKeyword: String
        /// How many scenarios CucumberSwift reads in it, and how many steps each has.
        let scenarioSteps: [Int]

        var text: String { lines.joined(separator: "\n") }
    }

    /// The lines of a generated feature after its Background, which are the same in each of a language's
    /// files, and the lines of its table and doc string within them.
    struct Body {
        var lines = [String]()
        var scenarioSteps = [Int]()
        var tableHeader = 0
        var docStringEnd = 0

        init(scenarios: [String], outlines: [String], examples: [String], rules: [String], steps: [String]) {
            let given = steps[0]
            let stepLines = steps.enumerated().map { index, form in "    \(form)step \(index + 1)" }
            for scenario in scenarios {
                lines += ["  \(scenario): A scenario", "    \(given)a table"]
                tableHeader = lines.count + 1
                lines += ["      | a | b |", "      | 1 | 2 |", "    \(given)a doc string", "      \"\"\"", "      A doc string"]
                docStringEnd = lines.count + 1
                lines += ["      \"\"\""] + stepLines + [""]
                scenarioSteps.append(1 + 2 + stepLines.count)
            }
            for outline in outlines where !examples.isEmpty {
                lines += ["  \(outline): An outline", "    \(given)a step with <value>", ""]
                for examples in examples {
                    lines += ["    \(examples): Some examples", "      | value |", "      | 1     |", ""]
                    scenarioSteps.append(1 + 1)
                }
            }
            for rule in rules {
                lines += ["  \(rule): A rule", "", "    \(scenarios[0]): A scenario in a rule", "      \(given)a step in a rule", ""]
                scenarioSteps.append(1 + 1)
            }
        }
    }

    private static let languagesFile = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources/CucumberSwift/Gherkin/Core/Languages.swift")

    private static let stepKeys = ["given", "when", "then", "and", "but"]
    // Not a keyword in any language: "A description" starts with an And step in Czech.
    private static let description = "Lorem ipsum dolor sit amet."

    /// Every language in the language data.
    static let languages = readLanguages()

    /// Every language in the language data, read from the JSON in Languages.swift.
    private static func readLanguages() -> [Language] {
        guard let source = try? String(contentsOf: languagesFile, encoding: .utf8),
              let start = source.range(of: "\"\"\""),
              let end = source.range(of: "\"\"\"", options: .backwards),
              start.upperBound <= end.lowerBound,
              let object = try? JSONSerialization.jsonObject(with: Data(source[start.upperBound..<end.lowerBound].utf8)),
              let json = object as? [String: Any] else { return [] }
        return json.compactMap { code, value -> Language? in
            // Besides the languages, the data has a "title" and an empty "properties".
            guard let language = value as? [String: Any], code != "properties" else { return nil }
            guard language["feature"] != nil else {
                XCTFail("Language '\(code)' has no Feature keywords")
                return nil
            }
            return Language(code: code, keywords: language.compactMapValues { $0 as? [String] })
        }
        .sorted { $0.code < $1.code }
    }

    /// The valid feature files for `language`: as many as it has forms of Feature or of Background,
    /// since a feature has one of each. Every other keyword is used in every form in each file.
    /// A form CucumberSwift doesn't read as its keyword is left out, as the lint tool reads files as
    /// CucumberSwift does: an Examples keyword that is also a Scenario keyword in the same language.
    /// Any other form that CucumberSwift doesn't read, or this one if it starts to read it, fails the
    /// tests. Every step keyword is read, of more than one word or without a space after it too (#363).
    static func features(in language: Language) throws -> [GeneratedFeature] {
        let keywords = try XCTUnwrap(FeatureFile.Keywords(language: language.code), "No keywords for '\(language.code)'")
        // Each form must be read as its keyword, except an Examples keyword that is also a Scenario keyword.
        func headers(_ key: String, _ line: FeatureFile.Keywords.Line) -> [String] {
            let forms = language.forms(key)
            let read = forms.filter { keywords.line($0 + ": A title") == line }
            let expected = forms.filter { key != "examples" || !language.forms("scenario").contains($0) }
            XCTAssertEqual(read, expected, "\(language.code) \(key)")
            return read
        }
        let features = headers("feature", .feature)
        let backgrounds = headers("background", .background)
        let scenarios = headers("scenario", .scenario)
        let stepForms = Set(stepKeys.flatMap(language.forms))
        // A line starting with a form is read as a step with that form as its keyword, even when a shorter
        // form starts it too, such as Czech `A ` in `A také `, or the form has no space after it, as `前提`.
        let steps = stepForms
            .filter { keywords.line($0 + "x") == .step(keyword: $0.trimmingCharacters(in: .whitespaces)) }
            .sorted()
        // Every step form must be read as a step.
        XCTAssertEqual(steps, stepForms.sorted(), language.code)
        let given = try XCTUnwrap(steps.first, "No step keyword in '\(language.code)'")
        // Each file needs a Feature, a Background and a Scenario: fail rather than build none.
        for (kind, forms) in [("Feature", features), ("Background", backgrounds), ("Scenario", scenarios)] {
            _ = try XCTUnwrap(forms.first, "No \(kind) keyword in '\(language.code)'")
        }
        XCTAssertNil(keywords.line(description), language.code)
        let body = Body(
            scenarios: scenarios,
            outlines: headers("scenarioOutline", .scenarioOutline),
            examples: headers("examples", .examples),
            rules: headers("rule", .rule),
            steps: steps
        )
        return (0..<max(features.count, backgrounds.count)).map { index in
            let head = [
                "# language: \(language.code)",
                "\(features[index % features.count]): A feature",
                "  \(description)",
                "",
                "  \(backgrounds[index % backgrounds.count]): A background",
                "    \(given)a background step",
                ""
            ]
            return GeneratedFeature(
                language: language.code,
                lines: head + body.lines,
                tableHeader: head.count + body.tableHeader,
                tableRow: head.count + body.tableHeader + 1,
                afterFeature: 3,
                docStringEnd: head.count + body.docStringEnd,
                stepKeyword: given,
                scenarioSteps: body.scenarioSteps
            )
        }
    }

    static func allFeatures() throws -> [GeneratedFeature] {
        let features = try languages.flatMap(features(in:))
        XCTAssertFalse(features.isEmpty, "No languages read from \(languagesFile.path)")
        return features
    }

    /// The diagnostics for `feature` as "line:column message".
    private func diagnostics(_ feature: GeneratedFeature) -> [String] {
        var messages = [String]()
        FeatureChecker(file: "\(feature.language).feature", definitions: nil).check(contents: feature.text) {
            messages.append("\($0.line):\($0.column) \($0.message)")
        }
        return messages
    }

    func testEveryLanguageIsRead() throws {
        XCTAssertGreaterThan(Self.languages.count, 70)
        XCTAssertTrue(Self.languages.contains { $0.code == "en" })
        for language in Self.languages {
            XCTAssertNotNil(FeatureFile.Keywords(language: language.code), "CucumberSwift doesn't read '\(language.code)'")
        }
    }

    /// The generated files are valid: CucumberSwift reads every scenario and step in them.
    func testCucumberSwiftReadsEveryGeneratedFile() throws {
        for feature in try Self.allFeatures() {
            let parsed = FeatureFile(parsing: feature.text, uri: "\(feature.language).feature")
            XCTAssertEqual(parsed.problems, [], feature.language)
            let scenarios = parsed.features.first?.scenarios ?? []
            let steps = scenarios.flatMap { scenario in scenario.examples?.map(\.steps.count) ?? [scenario.steps.count] }
            XCTAssertEqual(steps, feature.scenarioSteps, feature.language)
        }
    }

    func testAValidFileHasNoWarningsInEveryLanguage() throws {
        for feature in try Self.allFeatures() {
            XCTAssertEqual(diagnostics(feature), [], "\(feature.language):\n\(feature.text)")
        }
    }

    func testFixFeatureFilesLeavesAValidFileUnchangedInEveryLanguage() throws {
        var expected = [String: String]()
        for (index, feature) in try Self.allFeatures().enumerated() {
            let file = directory.appendingPathComponent("\(feature.language)-\(index).feature")
            try feature.text.write(to: file, atomically: true, encoding: .utf8)
            expected[file.standardizedFileURL.path] = feature.text
        }
        let outcome = FeatureFixer.fix(paths: [directory.path])
        XCTAssertEqual(outcome.files.count, expected.count)
        XCTAssertEqual(outcome.changes.map(\.description), [])
        XCTAssertEqual(outcome.failures, [])
        for (file, text) in expected {
            XCTAssertEqual(try String(contentsOfFile: file, encoding: .utf8), text, file)
        }
    }

    func testATableRowWithACellTooManyIsReportedInEveryLanguage() throws {
        for var feature in try Self.allFeatures() {
            feature.lines[feature.tableRow - 1] = "      | 1 | 2 | 3 |"
            let expected = "\(feature.tableRow):7 This row has 3 cells, but the table's first row (line \(feature.tableHeader)) has 2"
            XCTAssertEqual(diagnostics(feature), [expected], feature.language)
        }
    }

    func testAStepOutsideAScenarioIsReportedInEveryLanguage() throws {
        for var feature in try Self.allFeatures() {
            feature.lines[feature.afterFeature - 1] = "  \(feature.stepKeyword)a step out of place"
            let expected = "\(feature.afterFeature):3 A step must be inside a Scenario or Background"
            XCTAssertEqual(diagnostics(feature), [expected], feature.language)
        }
    }

    func testAnUnclosedDocStringIsReportedInEveryLanguage() throws {
        for var feature in try Self.allFeatures() {
            // The doc string's opening delimiter is two lines above its closing one.
            let start = feature.docStringEnd - 2
            feature.lines.remove(at: feature.docStringEnd - 1)
            XCTAssertEqual(diagnostics(feature), ["\(start):1 This doc string is never closed"], feature.language)
        }
    }
}
