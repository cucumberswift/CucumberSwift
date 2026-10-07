@testable import CucumberSwiftLintTool
import Foundation
import XCTest

/// `LocalizedStepDefinitionNames.swift` lists every localized step type in CucumberSwift's `Generated/I18n.swift`,
/// such as `ES_Dado`, for the lint tool, which can't link CucumberSwift. This test builds the file from `I18n.swift`
/// and fails when they differ. To rewrite it, run:
///
///     CUCUMBERSWIFT_WRITE_LOCALIZED_STEP_NAMES=1 swift test --filter LocalizedStepDefinitionNameTests
final class LocalizedStepDefinitionNameTests: LintTestCase {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    private static let i18n = root.appendingPathComponent("Sources/CucumberSwift/Generated/I18n.swift")
    private static let names = root.appendingPathComponent("Sources/CucumberSwiftLintTool/LocalizedStepDefinitionNames.swift")

    private static let header = [
        "//",
        "//  LocalizedStepDefinitionNames.swift",
        "//  CucumberSwiftLintTool",
        "//",
        "//  Generated from CucumberSwift's Generated/I18n.swift by LocalizedStepDefinitionNameTests.",
        "//  Do not edit: change I18n.swift, then rewrite this file as that test describes.",
        "//",
        "",
        "extension StepDefinition {",
        "    /// The localized step definitions, such as `ES_Dado(…)`, and their macros, such as `#ES_Dado(…)`.",
        "    static let localizedNames: [String] = ["
    ]

    static func declarations(from i18n: String) throws -> String {
        var lines = header
        for (language, names) in try localizedSteps(in: i18n) {
            lines += ["        // \(language)"]
            lines += names.map { "        \"\($0)\"," }
        }
        lines += ["    ]", "}", ""]
        return lines.joined(separator: "\n")
    }

    /// The name of each step typealias in I18n.swift, grouped under the language comment above it.
    private static func localizedSteps(in i18n: String) throws -> [(language: String, names: [String])] {
        let typealiasPattern = try NSRegularExpression(pattern: #"^public typealias (\S+) = (?:GivenStep|WhenStep|ThenStep|AndStep|ButStep)$"#)
        var language = ""
        var steps = [(language: String, names: [String])]()
        for line in i18n.components(separatedBy: "\n") {
            if line.hasPrefix("// "), !["// Types", "// Steps"].contains(line) {
                language = String(line.dropFirst(3))
                continue
            }
            let range = NSRange(line.startIndex..., in: line)
            guard let match = typealiasPattern.firstMatch(in: line, range: range),
                  let nameRange = Range(match.range(at: 1), in: line) else { continue }
            if steps.last?.language != language {
                steps.append((language, []))
            }
            steps[steps.count - 1].names.append(String(line[nameRange]))
        }
        return steps
    }

    func testTheLocalizedNamesMatchI18n() throws {
        let expected = try Self.declarations(from: String(contentsOf: Self.i18n, encoding: .utf8))
        if ProcessInfo.processInfo.environment["CUCUMBERSWIFT_WRITE_LOCALIZED_STEP_NAMES"] == "1" {
            try expected.write(to: Self.names, atomically: true, encoding: .utf8)
        }
        let actual = try String(contentsOf: Self.names, encoding: .utf8)
        XCTAssertTrue(actual == expected, """
            LocalizedStepDefinitionNames.swift does not match I18n.swift. To rewrite it, run:
            CUCUMBERSWIFT_WRITE_LOCALIZED_STEP_NAMES=1 swift test --filter LocalizedStepDefinitionNameTests
            """)
    }

    func testEveryLocalizedStepDefinitionAndMacroIsRead() throws {
        let names = try Self.localizedSteps(in: String(contentsOf: Self.i18n, encoding: .utf8)).flatMap(\.names)
        XCTAssertGreaterThan(names.count, 500)
        let steps = names.map { name in "\(name)(\"a step\") { _, _ in }\n#\(name)(\"a step\") { }" }
        let file = directory.appendingPathComponent("Steps.swift")
        try steps.joined(separator: "\n").write(to: file, atomically: true, encoding: .utf8)
        var diagnostics = [Diagnostic]()
        let definitions = StepDefinition.read(file: file.path) { diagnostics.append($0) }
        XCTAssertEqual(definitions.map(\.line), Array(1...names.count * 2))
        XCTAssertTrue(diagnostics.isEmpty)
    }

    func testLocalizedStepDefinitionsInSeveralLanguages() throws {
        let messages = try lint("""
        # language: es
        Característica: Pepinos
          Escenario: Cesta
            Dado tengo 5 pepinos en mi "cesta"
            Cuando como 2 pepinos
            Entonces me quedan 3 pepinos
            Y no hay más pepinos
        """, steps: """
        #ES_Dado("tengo {int} pepinos en mi {string}") { (count: Int, container: String) in }
        ES_Cuando("como {int} pepinos") { _, _ in }
        FR_Soit("me quedan {int} pepinos") { _, _ in }
        #JA_ならば("no hay más pepinos") { }
        """)
        XCTAssertEqual(messages, [])
    }

    func testANameThatOnlyStartsWithALocalizedNameIsNotAStepDefinition() throws {
        let messages = try lint("""
        Feature: F
          Scenario: S
            Given nothing defines this
        """, steps: """
        Given("something else") { _, _ in }
        ES_DadoX("nothing defines this") { _, _ in }
        XES_Dado("nothing defines this") { _, _ in }
        """)
        XCTAssertEqual(messages, ["3:5 Undefined step: no step definition matches \"nothing defines this\""])
    }
}
