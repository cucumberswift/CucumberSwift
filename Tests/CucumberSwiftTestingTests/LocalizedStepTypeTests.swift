//
//  LocalizedStepTypeTests.swift
//  CucumberSwiftTestingTests
//

@testable import CucumberSwiftTesting
import Foundation
import Testing

/// `LocalizedStepTypes.swift` declares each localized step type of CucumberSwift's `Generated/I18n.swift`,
/// such as `ES_Dado` for `GivenStep`, which the localized macros, such as `#ES_Dado`, expand to. These
/// tests build the file from `I18n.swift` and fail when they differ. To rewrite it, run:
///
///     CUCUMBERSWIFT_WRITE_LOCALIZED_STEP_TYPES=1 swift test --filter LocalizedStepTypeTests
@Suite struct LocalizedStepTypeTests {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    private static let i18n = root.appendingPathComponent("Sources/CucumberSwift/Generated/I18n.swift")
    private static let stepTypes = root.appendingPathComponent("Sources/CucumberSwiftTesting/LocalizedStepTypes.swift")

    private static let header = [
        "//",
        "//  LocalizedStepTypes.swift",
        "//  CucumberSwiftTesting",
        "//",
        "//  Generated from CucumberSwift's Generated/I18n.swift by LocalizedStepTypeTests.",
        "//  Do not edit: change I18n.swift, then rewrite this file as that test describes.",
        "//",
        "//  The step types only: the runner has no Swift DSL for features and scenarios.",
        "//"
    ]

    /// The file's contents: each step typealias of I18n.swift, under its language's name.
    static func declarations(from i18n: String) throws -> String {
        let typealiasPattern = try NSRegularExpression(pattern: #"^public typealias \S+ = (GivenStep|WhenStep|ThenStep|AndStep|ButStep)$"#)
        var lines = header
        var language = ""
        var languageOfLastStep = ""
        for line in i18n.components(separatedBy: "\n") {
            if line.hasPrefix("// "), !["// Types", "// Steps"].contains(line) {
                language = String(line.dropFirst(3))
                continue
            }
            guard typealiasPattern.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil else { continue }
            if language != languageOfLastStep {
                lines += ["", "// MARK: \(language)"]
                languageOfLastStep = language
            }
            lines.append(line)
        }
        return (lines + [""]).joined(separator: "\n")
    }

    @Test func theLocalizedStepTypesMatchI18n() throws {
        let expected = try Self.declarations(from: String(contentsOf: Self.i18n, encoding: .utf8))
        if ProcessInfo.processInfo.environment["CUCUMBERSWIFT_WRITE_LOCALIZED_STEP_TYPES"] == "1" {
            try expected.write(to: Self.stepTypes, atomically: true, encoding: .utf8)
        }
        let actual = try String(contentsOf: Self.stepTypes, encoding: .utf8)
        #expect(actual == expected, """
            LocalizedStepTypes.swift does not match I18n.swift. To rewrite it, run:
            CUCUMBERSWIFT_WRITE_LOCALIZED_STEP_TYPES=1 swift test --filter LocalizedStepTypeTests
            """)
    }

    /// Every localized macro, such as `#ES_Dado`, expands to its step type, so each one needs a type here.
    @Test func everyLocalizedMacroHasAStepType() throws {
        let macros = try String(contentsOf: Self.root.appendingPathComponent("Sources/CucumberSwiftTestingMacros/LocalizedStepDefinitionMacros.swift"),
                                encoding: .utf8)
        let macroPattern = try NSRegularExpression(pattern: #"^public macro (\S+)<each Argument>"#, options: .anchorsMatchLines)
        let macroNames = Set(macroPattern.matches(in: macros, range: NSRange(macros.startIndex..., in: macros)).compactMap { match in
            Range(match.range(at: 1), in: macros).map { String(macros[$0]) }
        })
        let stepTypes = try String(contentsOf: Self.stepTypes, encoding: .utf8)
        let typePattern = try NSRegularExpression(pattern: #"^public typealias (\S+) = "#, options: .anchorsMatchLines)
        let typeNames = Set(typePattern.matches(in: stepTypes, range: NSRange(stepTypes.startIndex..., in: stepTypes)).compactMap { match in
            Range(match.range(at: 1), in: stepTypes).map { String(stepTypes[$0]) }
        })
        #expect(!macroNames.isEmpty)
        #expect(macroNames == typeNames)
    }
}
