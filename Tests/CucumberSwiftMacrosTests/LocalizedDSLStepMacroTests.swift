//
//  LocalizedDSLStepMacroTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import Foundation
import XCTest

/// `LocalizedDSLStepMacros.swift` declares the DSL step macros, such as `#ES_Dado(I: abrirLaTienda())`, for every
/// localized step type in CucumberSwift's `Generated/I18n.swift`, with each of the labels `#Given` takes, and the
/// DSL's container macros, such as `#ES_Característica`, for every localized `Feature`, `Scenario`,
/// `ScenarioOutline`, `Background` and `Rule`. This test builds the file from `I18n.swift` and fails when they
/// differ. To rewrite it, run:
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
    /// What using a container macro without the Macros trait reports, the same as for `#Feature`.
    static let unavailableContainerMessage = "Turn on CucumberSwift's Macros package trait to use the DSL macros. In an Xcode project, that needs Xcode 26.4 or later."

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
        "//  The DSL step macros in each language, such as `#ES_Dado(I: abrirLaTienda())`, and the container macros,",
        "//  such as `#ES_Característica`, as DSLStepMacros.swift and DSLContainerMacros.swift declare them in English.",
        "//  CucumberSwiftTestingMacros compiles this file too, through a symlink.",
        "//",
        ""
    ]

    static func declarations(from i18n: String) throws -> String {
        let types = try localizedTypes(in: i18n)
        var lines = header + ["#if Macros"]
        var languageOfLastType = ""
        for type in types {
            if type.language != languageOfLastType {
                lines += ["", "// MARK: \(type.language)"]
                languageOfLastType = type.language
            }
            let english = english[type.type] ?? type.type
            let what = english == type.type ? "a part of a feature written in the Swift DSL" : "a step of a feature written in the Swift DSL"
            lines += ["", "/// `#\(english)\(english == type.type ? "" : "(I:)")` in \(type.language), \(what)."]
            for (index, declaration) in declarations(of: type, attributes: []).enumerated() {
                lines += (index == 0 ? [] : [""]) + declaration
            }
        }
        lines += ["#else", "// Without the Macros trait the macros are declared but unavailable, as in DSLStepMacros.swift."]
        for type in types {
            let message = english[type.type] == nil ? unavailableContainerMessage : unavailableMessage
            for declaration in declarations(of: type, attributes: ["@available(*, unavailable, message: \"\(message)\")"]) {
                lines += [""] + declaration
            }
        }
        lines += ["#endif", ""]
        return lines.joined(separator: "\n")
    }

    /// A step type's macro for each label, or a container's macros, as DSLContainerMacros.swift declares its type's.
    private static func declarations(of type: LocalizedStep, attributes: [String]) -> [[String]] {
        let head = ["@freestanding(expression)", "@discardableResult"] + attributes
        func macro(_ signature: [String], _ implementation: String) -> [String] {
            head + signature + ["    = #externalMacro(module: \"CucumberSwiftMacrosPlugin\", type: \"\(implementation)\")"]
        }
        let name = type.name
        switch type.type {
            case "Feature":
                return [macro(["public macro \(name)(_ title: String,",
                               "    tags: [String] = [],",
                               "    @ScenarioBuilder _ content: () -> [ScenarioDSL]) -> Feature"], "DSLFeatureMacro")]
            case "Scenario":
                return [macro(["public macro \(name)(_ title: String,",
                               "    description: String = \"\",",
                               "    tags: [String] = [],",
                               "    @StepBuilder _ content: () -> [StepDSL]) -> Scenario"], "DSLScenarioMacro")]
            case "ScenarioOutline":
                return ["String", "(T) -> String"].map { title in
                    macro(["public macro \(name)<T>(_ title: \(title),",
                           "    tags: [String] = [],",
                           "    description: String = \"\",",
                           "    headers: T.Type,",
                           "    @StepBuilder steps: (T) -> [StepDSL],",
                           "    examples: () -> [T]) -> ScenarioOutline"], "DSLScenarioMacro")
                }
            case "Background":
                return [macro(["public macro \(name)(@StepBuilder _ content: () -> [StepDSL]) -> Background"], "DSLPartMacro")]
            case "Rule":
                return [macro(["public macro \(name)(_ title: String,",
                               "    tags: [String] = [],",
                               "    @ScenarioBuilder _ content: () -> [ScenarioDSL]) -> Rule"], "DSLScenarioMacro")]
            default:
                return labels.map { label in
                    macro(["public macro \(name)<Handler>(\(label == "_" ? "_ handler" : "\(label) handler"): Handler) -> \(type.type)"],
                          "DSLStepMacro")
                }
        }
    }

    /// Each step and container typealias in I18n.swift, under the language comment above it.
    private static func localizedTypes(in i18n: String) throws -> [LocalizedStep] {
        let typealiasPattern = try NSRegularExpression(
            pattern: #"^public typealias (\S+) = (GivenStep|WhenStep|ThenStep|AndStep|ButStep|Feature|Scenario|ScenarioOutline|Background|Rule)$"#)
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

    func testEveryLocalizedTypeHasItsMacros() throws {
        let source = try String(contentsOf: Self.i18n, encoding: .utf8)
        func count(_ type: String) -> Int {
            source.components(separatedBy: "\n").filter { $0.hasSuffix(" = \(type)") }.count
        }
        let stepTypes = Self.english.keys.map(count).reduce(0, +)
        // A step type has a macro per label, a ScenarioOutline two and the other containers one, each declared
        // twice: available with the Macros trait, and unavailable without it.
        let containers = count("Feature") + count("Scenario") + count("ScenarioOutline") * 2 + count("Background") + count("Rule")
        let macros = try String(contentsOf: Self.macros, encoding: .utf8)
        XCTAssertEqual((stepTypes * Self.labels.count + containers) * 2, macros.components(separatedBy: "public macro ").count - 1)
        XCTAssertTrue(macros.contains("public macro ES_Dado<Handler>(I handler: Handler) -> GivenStep"))
        XCTAssertTrue(macros.contains("public macro ES_Característica(_ title: String,"))
        // The English macros take the same labels, and say the same when the trait is off.
        let english = try String(contentsOf: Self.englishMacros, encoding: .utf8)
        for label in Self.labels {
            let parameter = label == "_" ? "_ handler" : "\(label) handler"
            XCTAssertTrue(english.contains("public macro Given<Handler>(\(parameter): Handler) -> GivenStep"), label)
        }
        XCTAssertTrue(english.contains(Self.unavailableMessage))
        let englishContainers = try String(contentsOf: Self.root.appendingPathComponent("Sources/CucumberSwiftMacros/DSLContainerMacros.swift"),
                                           encoding: .utf8)
        XCTAssertTrue(englishContainers.contains(Self.unavailableContainerMessage))
    }
}
#endif
