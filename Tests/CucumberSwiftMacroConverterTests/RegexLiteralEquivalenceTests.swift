//
//  RegexLiteralEquivalenceTests.swift
//  CucumberSwiftMacroConverterTests
//

#if Macros
import CucumberSwiftExpressions
import XCTest

/// A converted regex literal has to match the steps the literal matched, with the same capture groups. Each
/// test converts a regex literal, then matches steps with Swift's `Regex`, as CucumberSwift matches the
/// literal, and with the string regular expression the converter wrote, as it matches that.
final class RegexLiteralEquivalenceTests: ConverterTestCase {
    private struct Case {
        let pattern: String
        let steps: [String]
    }

    private let cases = [
        Case(pattern: #"^I have (\d+) cukes$"#, steps: ["I have 12 cukes", "I have 12 cukes!", "I have  cukes", "xI have 1 cukes"]),
        Case(pattern: #"I have (\d+) cukes"#, steps: ["I have 12 cukes", "I have 12 cukes!", "so I have 12 cukes", "I have a cukes"]),
        Case(pattern: #"^I have (\d+) cukes"#, steps: ["I have 3 cukes", "I have 3 cukes today"]),
        Case(pattern: #"I have (\d+) cukes$"#, steps: ["I have 3 cukes", "now I have 3 cukes"]),
        Case(pattern: #"I put (\d+) in (?:my )?(\w+)"#, steps: ["I put 2 in my basket", "I put 2 in basket", "I put 2 in my "]),
        Case(pattern: #"I say "(\w+)""#, steps: ["I say \"hello\"", "I say hello", "I say \"hello\" twice"]),
        Case(pattern: #"cost \$(\d+)\.(\d{2})"#, steps: ["cost $5.00", "cost $5.0", "cost 5.00"]),
        Case(pattern: #"I (?:eat|drink) (\d+|no) (cukes?|tomatoes)"#, steps: ["I eat 2 cukes", "I drink no tomatoes", "I eat 2 pears"]),
        Case(pattern: #"a|b"#, steps: ["a", "b", "ab", ""]),
        Case(pattern: #"(\w+) is (?:very )?(\w+)"#, steps: ["it is red", "it is very red", "it is"]),
        Case(pattern: #"^no groups here$"#, steps: ["no groups here", "no groups here "])
    ]

    /// The string regular expression written for the regex literal, undone from its Swift string literal.
    private func convertedPattern(for pattern: String) throws -> String {
        let result = try ConverterTool.convert("import CucumberSwift\nGiven(#/\(pattern)/#) { _, _ in }\n")
        let start = try XCTUnwrap(result.source.range(of: "#Given(\""))
        let end = try XCTUnwrap(result.source.range(of: "\")", options: .backwards))
        return String(result.source[start.upperBound..<end.lowerBound])
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }

    func testAConvertedRegexLiteralMatchesTheSameStepsWithTheSameCaptureGroups() throws {
        guard #available(macOS 13, *) else { throw XCTSkip("Swift's Regex needs macOS 13") }
        for item in cases {
            let converted = try convertedPattern(for: item.pattern)
            let expression = CucumberExpression(converted)
            let regex = try Regex(item.pattern)
            for step in item.steps {
                let literal = try regex.wholeMatch(in: step).map { match in
                    (1..<match.output.count).map { match.output[$0].substring.map(String.init) }
                }
                let string = try expression.match(in: step).map { try $0.allParameters(\.anonymous) }
                XCTAssertEqual(literal.map { $0.map { $0 ?? "" } }, string, "\(item.pattern) on \"\(step)\" as \(converted)")
            }
        }
    }
}
#endif
