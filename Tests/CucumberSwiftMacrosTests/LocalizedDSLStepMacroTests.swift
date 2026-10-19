//
//  LocalizedDSLStepMacroTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import Foundation
import XCTest

/// `LocalizedDSLStepMacros.swift` declares the DSL step macros, such as `#ES_Dado(I: abrirLaTienda())`, for every
/// localized step type in CucumberSwift's `Generated/I18n.swift`, with each of the labels `#Given` takes. This test
/// builds the file from `I18n.swift` and fails when they differ. To rewrite it, run:
///
///     CUCUMBERSWIFT_WRITE_LOCALIZED_DSL_MACROS=1 swift test --traits Macros --filter LocalizedDSLStepMacroTests
final class LocalizedDSLStepMacroTests: XCTestCase {
    /// A step typealias in I18n.swift, such as `ES_Dado = GivenStep` under "Spanish".
    private struct LocalizedStep {
        let language: String
        let name: String
        let type: String
    }

    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    private static let i18n = root.appendingPathComponent("Sources/CucumberSwift/Generated/I18n.swift")
    private static let macros = root.appendingPathComponent("Sources/CucumberSwiftMacros/LocalizedDSLStepMacros.swift")
    private static let englishMacros = root.appendingPathComponent("Sources/CucumberSwiftMacros/DSLStepMacros.swift")

    /// What using a macro without the Macros trait reports, the same as for `#Given(I:)`.
    static let unavailableMessage = "Turn on CucumberSwift's Macros package trait to use the DSL step macros. In an Xcode project, that needs Xcode 26.4 or later."

    /// The labels a DSL step takes, as `Given(I:)` does.
    static let labels = ["_", "I", "it", "my", "some", "a", "the"]

    /// The English macro each step type has.
    private static let english = [
        "GivenStep": "Given",
        "WhenStep": "When",
        "ThenStep": "Then",
        "AndStep": "And",
        "ButStep": "But"
    ]

    private static let header = [
        "//",
        "//  LocalizedDSLStepMacros.swift",
        "//  CucumberSwiftMacros",
        "//",
        "//  Generated from CucumberSwift's Generated/I18n.swift by LocalizedDSLStepMacroTests.",
        "//  Do not edit: change I18n.swift, then rewrite this file as that test describes.",
        "//",
        "//  The DSL step macros in each language, such as `#ES_Dado(I: abrirLaTienda())`, as DSLStepMacros.swift",
        "//  declares them in English. CucumberSwiftTestingMacros compiles this file too, through a symlink.",
        "//",
        ""
    ]

    static func declarations(from i18n: String) throws -> String {
        let steps = try localizedSteps(in: i18n)
        var lines = header + ["#if Macros"]
        var languageOfLastStep = ""
        for step in steps {
            if step.language != languageOfLastStep {
                lines += ["", "// MARK: \(step.language)"]
                languageOfLastStep = step.language
            }
            let english = english[step.type] ?? step.type
            lines += ["", "/// `#\(english)(I:)` in \(step.language), a step of a feature written in the Swift DSL."]
            for (index, label) in labels.enumerated() {
                lines += (index == 0 ? [] : [""]) + declaration(of: step, label: label, attributes: [])
            }
        }
        lines += ["#else", "// Without the Macros trait the macros are declared but unavailable, as in DSLStepMacros.swift."]
        let unavailable = "@available(*, unavailable, message: \"\(unavailableMessage)\")"
        for step in steps {
            for label in labels {
                lines += [""] + declaration(of: step, label: label, attributes: [unavailable])
            }
        }
        lines += ["#endif", ""]
        return lines.joined(separator: "\n")
    }

    private static func declaration(of step: LocalizedStep, label: String, attributes: [String]) -> [String] {
        let parameter = label == "_" ? "_ handler" : "\(label) handler"
        return ["@freestanding(expression)", "@discardableResult"] + attributes + [
            "public macro \(step.name)<Handler>(\(parameter): Handler) -> \(step.type)",
            "    = #externalMacro(module: \"CucumberSwiftMacrosPlugin\", type: \"DSLStepMacro\")"
        ]
    }

    /// Each step typealias in I18n.swift, under the language comment above it.
    private static func localizedSteps(in i18n: String) throws -> [LocalizedStep] {
        let typealiasPattern = try NSRegularExpression(pattern: #"^public typealias (\S+) = (GivenStep|WhenStep|ThenStep|AndStep|ButStep)$"#)
        var language = ""
        var steps = [LocalizedStep]()
        for line in i18n.components(separatedBy: "\n") {
            if line.hasPrefix("// "), !["// Types", "// Steps"].contains(line) {
                language = String(line.dropFirst(3))
                continue
            }
            let range = NSRange(line.startIndex..., in: line)
            guard let match = typealiasPattern.firstMatch(in: line, range: range),
                  let nameRange = Range(match.range(at: 1), in: line),
                  let typeRange = Range(match.range(at: 2), in: line) else { continue }
            steps.append(LocalizedStep(language: language, name: String(line[nameRange]), type: String(line[typeRange])))
        }
        return steps
    }

    func testTheLocalizedDSLStepMacrosMatchI18n() throws {
        let expected = try Self.declarations(from: String(contentsOf: Self.i18n, encoding: .utf8))
        if ProcessInfo.processInfo.environment["CUCUMBERSWIFT_WRITE_LOCALIZED_DSL_MACROS"] == "1" {
            try expected.write(to: Self.macros, atomically: true, encoding: .utf8)
        }
        let actual = try String(contentsOf: Self.macros, encoding: .utf8)
        XCTAssertTrue(actual == expected, """
            LocalizedDSLStepMacros.swift does not match I18n.swift. To rewrite it, run:
            CUCUMBERSWIFT_WRITE_LOCALIZED_DSL_MACROS=1 swift test --traits Macros --filter LocalizedDSLStepMacroTests
            """)
    }

    func testEveryLocalizedStepTypeHasEachLabel() throws {
        let source = try String(contentsOf: Self.i18n, encoding: .utf8)
        let stepTypes = source.components(separatedBy: "\n").filter { line in
            Self.english.keys.contains { line.hasSuffix(" = \($0)") }
        }
        let macros = try String(contentsOf: Self.macros, encoding: .utf8)
        // Each label of each step type is declared twice: available with the Macros trait, and unavailable without it.
        XCTAssertEqual(stepTypes.count * Self.labels.count * 2, macros.components(separatedBy: "public macro ").count - 1)
        XCTAssertTrue(macros.contains("public macro ES_Dado<Handler>(I handler: Handler) -> GivenStep"))
        // The English macros take the same labels, and say the same when the trait is off.
        let english = try String(contentsOf: Self.englishMacros, encoding: .utf8)
        for label in Self.labels {
            let parameter = label == "_" ? "_ handler" : "\(label) handler"
            XCTAssertTrue(english.contains("public macro Given<Handler>(\(parameter): Handler) -> GivenStep"), label)
        }
        XCTAssertTrue(english.contains(Self.unavailableMessage))
    }
}
#endif
