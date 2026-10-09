//
//  RegexLiteralPattern.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftParser
import SwiftSyntax

/// A regex literal such as `#/^I have (\d+) cukes$/#`, written as the string regular expression the macros
/// take: `"^I have (\\d+) cukes$"`. CucumberSwift matches a regex literal with Swift's `Regex`, and a string
/// that starts with `^` and ends with `$` with `NSRegularExpression`. So the conversion is limited to the
/// syntax that both read alike, and anchors the pattern, because a regex literal has to match the whole step.
enum RegexLiteralPattern {
    /// The escapes of a letter that both engines read the same way.
    private static let sharedEscapes: Set<Character> = ["d", "D", "w", "W", "s", "S", "b", "B", "n", "r", "t"]

    /// The string literal for the regex literal, or why it can't be written as one.
    static func stringLiteral(for literal: RegexLiteralExprSyntax) throws -> StringLiteralExprSyntax {
        let pattern = literal.regex.text
        if let problem = unsupported(in: pattern) {
            throw Unconvertible(reason: "its regex literal \(problem), so it may not match the same steps as a string regular expression")
        }
        let anchored = anchored(pattern)
        let escaped = anchored.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let parsed = Parser.parse(source: "\"\(escaped)\"")
        guard !parsed.hasError,
              let string = parsed.statements.first?.item.as(StringLiteralExprSyntax.self),
              string.representedLiteralValue == anchored else {
            throw Unconvertible(reason: "its regex literal can't be written as a string")
        }
        return string.with(\.leadingTrivia, literal.leadingTrivia).with(\.trailingTrivia, literal.trailingTrivia)
    }

    /// The pattern as a string regular expression that has to match the whole step: between `^` and `$`.
    private static func anchored(_ pattern: String) -> String {
        let endsAtAnchor = pattern.hasSuffix("$")
            && pattern.dropLast().reversed().prefix { $0 == "\\" }.count.isMultiple(of: 2)
        return pattern.hasPrefix("^") && endsAtAnchor ? pattern : "^(?:\(pattern))$"
    }

    /// What in the pattern the two engines might read differently, or `nil` when nothing does.
    private static func unsupported(in pattern: String) -> String? {
        if pattern.contains("\n") { return "spans several lines" }
        let characters = Array(pattern)
        var index = 0
        var classDepth = 0
        var groups = [Bool]()
        while index < characters.count {
            let character = characters[index]
            switch character {
                case "\\":
                    guard index + 1 < characters.count else { return "ends with a backslash" }
                    let escaped = characters[index + 1]
                    if escaped.isLetter || escaped.isNumber, !sharedEscapes.contains(escaped) {
                        return "uses `\\\(escaped)`, which only Swift's regex reads"
                    }
                    index += 1
                case "[":
                    if classDepth > 0, characters.dropFirst(index + 1).first == ":" { return "uses a POSIX character class" }
                    classDepth += 1
                case "]" where classDepth > 0:
                    classDepth -= 1
                case "-" where classDepth > 0 && characters.dropFirst(index + 1).first == "-":
                    return "uses a character class operation"
                case "&" where classDepth > 0 && characters.dropFirst(index + 1).first == "&":
                    return "uses a character class operation"
                case "(" where classDepth == 0:
                    let rest = characters.dropFirst(index + 1)
                    if rest.first == "*" { return "uses a regex verb" }
                    let capturing = rest.first != "?"
                    if !capturing, !rest.starts(with: ["?", ":"]) { return "uses a group or option that only Swift's regex reads" }
                    if capturing, groups.contains(true) { return "has a capture group inside another" }
                    groups.append(capturing)
                case ")" where classDepth == 0:
                    _ = groups.popLast()
                default:
                    break
            }
            index += 1
        }
        return nil
    }
}
#endif
