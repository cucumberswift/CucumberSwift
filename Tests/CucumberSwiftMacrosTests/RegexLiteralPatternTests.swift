//
//  RegexLiteralPatternTests.swift
//  CucumberSwiftMacrosTests
//

#if Macros
import XCTest
@testable import CucumberSwiftMacrosPlugin

/// How the macros read a regex literal's captures. Each expected output is the type the compiler gives
/// the same literal (checked with Swift 6.2).
final class RegexLiteralPatternTests: XCTestCase {
    /// The captures as the regex's `Output` spells them, such as `(Substring, name: Substring?)`.
    private func output(_ pattern: String, isExtended: Bool = false, file: StaticString = #filePath, line: UInt = #line) -> String {
        let read = RegexLiteralPattern(pattern, isExtended: isExtended)
        XCTAssertTrue(read.isCertain, "\(pattern) should be read", file: file, line: line)
        let types = ["Substring"] + read.captures.map { ($0.name.map { "\($0): " } ?? "") + $0.type }
        return types.count == 1 ? "Substring" : "(\(types.joined(separator: ", ")))"
    }

    func testNumberedAndNamedCaptures() {
        XCTAssertEqual(output(#"^no captures$"#), "Substring")
        XCTAssertEqual(output(#"^I have (\d+) cukes$"#), "(Substring, Substring)")
        XCTAssertEqual(output(#"^(?<name>\w+) and (?<other>\w+)$"#), "(Substring, name: Substring, other: Substring)")
        XCTAssertEqual(output(#"^(a(b(c)))$"#), "(Substring, Substring, Substring, Substring)")
    }

    func testOptionalCaptures() {
        XCTAssertEqual(output(#"^(a)|(b)$"#), "(Substring, Substring?, Substring?)")
        XCTAssertEqual(output(#"^(?:(a)|b)(c)$"#), "(Substring, Substring?, Substring)")
        XCTAssertEqual(output(#"^(a|(b))$"#), "(Substring, Substring, Substring?)")
        XCTAssertEqual(output(#"^((a)?)?$"#), "(Substring, Substring?, Substring?)")
        XCTAssertEqual(output(#"^(a)??(b)*?(c)+?$"#), "(Substring, Substring?, Substring?, Substring)")
        XCTAssertEqual(output(#"^(x){0}$"#), "(Substring, Substring?)")
        XCTAssertEqual(output(#"^(\d+)(?:,(\d+))*$"#), "(Substring, Substring, Substring?)")
    }

    func testGroupsThatDoNotCapture() {
        XCTAssertEqual(output(#"^\((\d+)\)$"#), "(Substring, Substring)")
        XCTAssertEqual(output(#"^[(](\d+)[)]$"#), "(Substring, Substring)")
        XCTAssertEqual(output(#"^[[:alpha:]()]+(x)$"#), "(Substring, Substring)")
        XCTAssertEqual(output(#"^\Q(literal)\E(z)$"#), "(Substring, Substring)")
        XCTAssertEqual(output(#"^(?i)(case)$"#), "(Substring, Substring)")
        XCTAssertEqual(output(#"^(?i:(a))(b)$"#), "(Substring, Substring, Substring)")
        XCTAssertEqual(output(#"^(?=(look))\w+$"#), "(Substring, Substring)")
        XCTAssertEqual(output(#"^(?>(atomic))$"#), "(Substring, Substring)")
    }

    func testExtendedSyntax() {
        let pattern = "\n    ^ I \\s have \\s (\\d+) # the count (of cukes)\n    \\s cukes (?<where>\\s in \\s \\w+)?\n    $\n    "
        XCTAssertEqual(output(pattern, isExtended: true), "(Substring, Substring, where: Substring?)")
    }

    func testWhatTheMacroCannotReadIsLeftToTheCompiler() {
        // Syntax ICU doesn't read, or that changes what captures, so the counts can't be checked against each other.
        let patterns = [
            #"^(?'quoted'\w+)$"#, #"^(?P<python>\w+)$"#, #"^(a){,2}$"#, #"^(?|(a)|(b))$"#,
            #"^(?n)(a)(?<b>b)$"#, #"^(?x) (a) $"#, #"^(a$"#, #"^a)$"#, #"^(*atomic:a)$"#
        ]
        for pattern in patterns {
            XCTAssertFalse(RegexLiteralPattern(pattern, isExtended: false).isCertain, pattern)
        }
    }
}
#endif
