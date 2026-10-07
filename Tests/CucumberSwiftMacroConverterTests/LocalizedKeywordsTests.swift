//
//  LocalizedKeywordsTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import XCTest

final class LocalizedKeywordsTests: ConverterTestCase {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    /// `LocalizedKeywords.swift` lists the localized step types of CucumberSwift's `Generated/I18n.swift`.
    /// To rewrite it, run:
    ///
    ///     CUCUMBERSWIFT_WRITE_LOCALIZED_KEYWORDS=1 swift test --traits Macros --filter LocalizedKeywordsTests
    func testTheLocalizedKeywordsMatchI18n() throws {
        let i18n = try String(contentsOf: Self.root.appendingPathComponent("Sources/CucumberSwift/Generated/I18n.swift"), encoding: .utf8)
        let pattern = try NSRegularExpression(pattern: #"^public typealias (\S+) = (GivenStep|WhenStep|ThenStep|AndStep|ButStep)$"#)
        let names = i18n.components(separatedBy: "\n").compactMap { line -> String? in
            let range = NSRange(line.startIndex..., in: line)
            return pattern.firstMatch(in: line, range: range)
                .flatMap { Range($0.range(at: 1), in: line) }
                .map { String(line[$0]) }
        }
        let file = Self.root.appendingPathComponent("Sources/CucumberSwiftMacroConverterTool/LocalizedKeywords.swift")
        let current = try String(contentsOf: file, encoding: .utf8)
        let lines = ["//", "//  LocalizedKeywords.swift", "//  CucumberSwiftMacroConverterTool", "//",
                     "//  Generated from CucumberSwift's Generated/I18n.swift by LocalizedKeywordsTests.",
                     "//  Do not edit: change I18n.swift, then rewrite this file as that test describes.",
                     "//", "", "#if Macros", "enum LocalizedKeywords {",
                     "    /// Every localized step definition name, such as `ES_Dado`, which has a macro of the same name.",
                     "    static let all: Set<String> = ["]
            + names.enumerated().map { "        \"\($1)\"" + ($0 == names.count - 1 ? "" : ",") }
            + ["    ]", "}", "#endif", ""]
        let expected = lines.joined(separator: "\n")
        if ProcessInfo.processInfo.environment["CUCUMBERSWIFT_WRITE_LOCALIZED_KEYWORDS"] == "1" {
            try expected.write(to: file, atomically: true, encoding: .utf8)
        }
        XCTAssertTrue(current == expected || ProcessInfo.processInfo.environment["CUCUMBERSWIFT_WRITE_LOCALIZED_KEYWORDS"] == "1", """
            LocalizedKeywords.swift does not match I18n.swift. To rewrite it, run:
            CUCUMBERSWIFT_WRITE_LOCALIZED_KEYWORDS=1 swift test --traits Macros --filter LocalizedKeywordsTests
            """)
        XCTAssertEqual(current.components(separatedBy: "\n").filter { $0.hasPrefix("        \"") }.count, names.count)
        XCTAssertTrue(current.contains("\"ES_Dado\""))
    }
}
#endif
