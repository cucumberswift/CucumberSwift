//
//  LocalizedStepDefinitionMacroTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import Foundation
import XCTest

/// `LocalizedStepDefinitionMacros.swift` declares a macro for every localized step type in CucumberSwift's
/// `Generated/I18n.swift`, such as `#ES_Dado` for `ES_Dado`. This test builds the file from `I18n.swift`
/// and fails when they differ. To rewrite it, run:
///
///     CUCUMBERSWIFT_WRITE_LOCALIZED_MACROS=1 swift test --traits Macros --filter LocalizedStepDefinitionMacroTests
final class LocalizedStepDefinitionMacroTests: XCTestCase {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    private static let i18n = root.appendingPathComponent("Sources/CucumberSwift/Generated/I18n.swift")
    private static let macros = root.appendingPathComponent("Sources/CucumberSwiftMacros/LocalizedStepDefinitionMacros.swift")

    /// The English macro each step type has.
    private static let englishMacros = [
        "GivenStep": "Given",
        "WhenStep": "When",
        "ThenStep": "Then",
        "AndStep": "And",
        "ButStep": "But"
    ]

    /// The file's contents: one macro per step typealias, under its language's name.
    static func declarations(from i18n: String) throws -> String {
        let typealiasPattern = try NSRegularExpression(pattern: #"^public typealias (\S+) = (GivenStep|WhenStep|ThenStep|AndStep|ButStep)$"#)
        var language = ""
        var lines = [
            "//",
            "//  LocalizedStepDefinitionMacros.swift",
            "//  CucumberSwiftMacros",
            "//",
            "//  Generated from CucumberSwift's Generated/I18n.swift by LocalizedStepDefinitionMacroTests.",
            "//  Do not edit: change I18n.swift, then rewrite this file as that test describes.",
            "//",
            "",
            "#if Macros"
        ]
        var languageOfLastMacro = ""
        for line in i18n.components(separatedBy: "\n") {
            if line.hasPrefix("// "), !["// Types", "// Steps"].contains(line) {
                language = String(line.dropFirst(3))
                continue
            }
            let range = NSRange(line.startIndex..., in: line)
            guard let match = typealiasPattern.firstMatch(in: line, range: range),
                  let nameRange = Range(match.range(at: 1), in: line),
                  let typeRange = Range(match.range(at: 2), in: line) else { continue }
            let name = line[nameRange]
            let type = String(line[typeRange])
            if language != languageOfLastMacro {
                lines += ["", "// MARK: \(language)"]
                languageOfLastMacro = language
            }
            lines += [
                "",
                "/// `#\(englishMacros[type] ?? type)` in \(language).",
                "@freestanding(expression)",
                "@discardableResult",
                "public macro \(name)<each Argument>(_ expression: StaticString,",
                "    _ body: (repeat each Argument) async throws -> Void) -> \(type)",
                "    = #externalMacro(module: \"CucumberSwiftMacrosPlugin\", type: \"StepDefinitionMacro\")"
            ]
        }
        lines += ["#endif", ""]
        return lines.joined(separator: "\n")
    }

    func testTheLocalizedMacrosMatchI18n() throws {
        let expected = try Self.declarations(from: String(contentsOf: Self.i18n, encoding: .utf8))
        if ProcessInfo.processInfo.environment["CUCUMBERSWIFT_WRITE_LOCALIZED_MACROS"] == "1" {
            try expected.write(to: Self.macros, atomically: true, encoding: .utf8)
        }
        let actual = try String(contentsOf: Self.macros, encoding: .utf8)
        XCTAssertTrue(actual == expected, """
            LocalizedStepDefinitionMacros.swift does not match I18n.swift. To rewrite it, run:
            CUCUMBERSWIFT_WRITE_LOCALIZED_MACROS=1 swift test --traits Macros --filter LocalizedStepDefinitionMacroTests
            """)
    }

    func testEveryLocalizedStepTypeHasAMacro() throws {
        let source = try String(contentsOf: Self.i18n, encoding: .utf8)
        let stepTypes = source.components(separatedBy: "\n").filter { line in
            Self.englishMacros.keys.contains { line.hasSuffix(" = \($0)") }
        }
        let macros = try String(contentsOf: Self.macros, encoding: .utf8)
        XCTAssertEqual(stepTypes.count, macros.components(separatedBy: "public macro ").count - 1)
        XCTAssertTrue(macros.contains("public macro ES_Dado<each Argument>"))
    }
}
#endif
