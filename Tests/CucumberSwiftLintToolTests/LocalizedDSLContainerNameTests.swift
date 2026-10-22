@testable import CucumberSwiftLintTool
import Foundation
import XCTest

/// `LocalizedDSLContainerNames.swift` lists every localized container of the Swift DSL in CucumberSwift's
/// `Generated/I18n.swift`, such as `ES_Escenario`, for the lint tool's DSL check. This test builds the file from
/// `I18n.swift` and fails when they differ. To rewrite it, run:
///
///     CUCUMBERSWIFT_WRITE_LOCALIZED_CONTAINER_NAMES=1 swift test --filter LocalizedDSLContainerNameTests
final class LocalizedDSLContainerNameTests: XCTestCase {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    private static let i18n = root.appendingPathComponent("Sources/CucumberSwift/Generated/I18n.swift")
    private static let names = root.appendingPathComponent("Sources/CucumberSwiftLintTool/LocalizedDSLContainerNames.swift")

    private static let header = [
        "//",
        "//  LocalizedDSLContainerNames.swift",
        "//  CucumberSwiftLintTool",
        "//",
        "//  Generated from CucumberSwift's Generated/I18n.swift by LocalizedDSLContainerNameTests.",
        "//  Do not edit: change I18n.swift, then rewrite this file as that test describes.",
        "//",
        "",
        "extension DSLPlacementCheck {",
        "    /// The localized containers of the Swift DSL, such as `ES_Escenario(…)`, and their macros, such as `#ES_Escenario(…)`.",
        "    static let localizedContainerNames: [String] = ["
    ]

    static func declarations(from i18n: String) throws -> String {
        let pattern = try NSRegularExpression(pattern: #"^public typealias (\S+) = (?:Feature|Scenario|ScenarioOutline|Background|Rule)$"#)
        var lines = header
        var language = ""
        var languageOfLastName = ""
        for line in i18n.components(separatedBy: "\n") {
            if line.hasPrefix("// "), !["// Types", "// Steps"].contains(line) {
                language = String(line.dropFirst(3))
                continue
            }
            guard let match = pattern.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  let range = Range(match.range(at: 1), in: line) else { continue }
            if language != languageOfLastName {
                lines.append("        // \(language)")
                languageOfLastName = language
            }
            lines.append("        \"\(line[range])\",")
        }
        lines += ["    ]", "}", ""]
        return lines.joined(separator: "\n")
    }

    func testTheLocalizedContainerNamesMatchI18n() throws {
        let expected = try Self.declarations(from: String(contentsOf: Self.i18n, encoding: .utf8))
        if ProcessInfo.processInfo.environment["CUCUMBERSWIFT_WRITE_LOCALIZED_CONTAINER_NAMES"] == "1" {
            try expected.write(to: Self.names, atomically: true, encoding: .utf8)
        }
        let actual = try String(contentsOf: Self.names, encoding: .utf8)
        XCTAssertTrue(actual == expected, """
            LocalizedDSLContainerNames.swift does not match I18n.swift. To rewrite it, run:
            CUCUMBERSWIFT_WRITE_LOCALIZED_CONTAINER_NAMES=1 swift test --filter LocalizedDSLContainerNameTests
            """)
        XCTAssertTrue(DSLPlacementCheck.containerNames.contains("ES_Escenario"))
    }
}
