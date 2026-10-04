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
    /// A step typealias in I18n.swift, such as `ES_Dado = GivenStep` under "Spanish".
    private struct LocalizedStep {
        let language: String
        let name: String
        let type: String
    }

    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    private static let i18n = root.appendingPathComponent("Sources/CucumberSwift/Generated/I18n.swift")
    private static let macros = root.appendingPathComponent("Sources/CucumberSwiftMacros/LocalizedStepDefinitionMacros.swift")

    /// What using a macro without the Macros trait reports, the same as for `#Given`.
    static let unavailableMessage = "Turn on CucumberSwift's Macros package trait to use the step definition macros. In an Xcode project, that needs Xcode 26.4 or later."

    /// The English macro each step type has.
    private static let englishMacros = [
        "GivenStep": "Given",
        "WhenStep": "When",
        "ThenStep": "Then",
        "AndStep": "And",
        "ButStep": "But"
    ]

    /// The file's contents: one macro per step typealias, under its language's name.
    private static let header = [
        "//",
        "//  LocalizedStepDefinitionMacros.swift",
        "//  CucumberSwiftMacros",
        "//",
        "//  Generated from CucumberSwift's Generated/I18n.swift by LocalizedStepDefinitionMacroTests.",
        "//  Do not edit: change I18n.swift, then rewrite this file as that test describes.",
        "//",
        ""
    ]

    static func declarations(from i18n: String) throws -> String {
        let macros = try localizedSteps(in: i18n)
        var lines = header + ["#if Macros"]
        var languageOfLastMacro = ""
        for macro in macros {
            if macro.language != languageOfLastMacro {
                lines += ["", "// MARK: \(macro.language)"]
                languageOfLastMacro = macro.language
            }
            lines += ["", "/// `#\(englishMacros[macro.type] ?? macro.type)` in \(macro.language)."]
                + declaration(of: macro, attributes: [])
        }
        lines += ["#else", "// Without the Macros trait the macros are declared but unavailable, as in StepDefinitionMacros.swift."]
        for macro in macros {
            lines += [""] + declaration(of: macro, attributes: ["@available(*, unavailable, message: \"\(unavailableMessage)\")"])
        }
        lines += ["#endif", ""]
        return lines.joined(separator: "\n")
    }

    private static func declaration(of macro: LocalizedStep, attributes: [String]) -> [String] {
        ["@freestanding(expression)", "@discardableResult"] + attributes + [
            "public macro \(macro.name)<each Argument>(_ expression: String,",
            "    _ body: (repeat each Argument) async throws -> Void) -> \(macro.type)",
            "    = #externalMacro(module: \"CucumberSwiftMacrosPlugin\", type: \"StepDefinitionMacro\")"
        ]
    }

    /// Each step typealias in I18n.swift, under the language comment above it.
    private static func localizedSteps(in i18n: String) throws -> [LocalizedStep] {
        let typealiasPattern = try NSRegularExpression(pattern: #"^public typealias (\S+) = (GivenStep|WhenStep|ThenStep|AndStep|ButStep)$"#)
        var language = ""
        var macros = [LocalizedStep]()
        for line in i18n.components(separatedBy: "\n") {
            if line.hasPrefix("// "), !["// Types", "// Steps"].contains(line) {
                language = String(line.dropFirst(3))
                continue
            }
            let range = NSRange(line.startIndex..., in: line)
            guard let match = typealiasPattern.firstMatch(in: line, range: range),
                  let nameRange = Range(match.range(at: 1), in: line),
                  let typeRange = Range(match.range(at: 2), in: line) else { continue }
            macros.append(LocalizedStep(language: language, name: String(line[nameRange]), type: String(line[typeRange])))
        }
        return macros
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
        // Each is declared twice: available with the Macros trait, unavailable without it.
        XCTAssertEqual(stepTypes.count * 2, macros.components(separatedBy: "public macro ").count - 1)
        XCTAssertTrue(macros.contains("public macro ES_Dado<each Argument>"))
        // The English macros say the same as the localized ones when the trait is off.
        let english = try String(contentsOf: Self.root.appendingPathComponent("Sources/CucumberSwiftMacros/StepDefinitionMacros.swift"),
                                 encoding: .utf8)
        XCTAssertEqual(english.components(separatedBy: "message: \"\(Self.unavailableMessage)\"").count - 1, 6)
    }
}
#endif
