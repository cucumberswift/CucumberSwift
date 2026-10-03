//
//  StepPattern.swift
//  CucumberSwiftMacrosPlugin
//

import CucumberSwiftExpressions
import Foundation

/// What a step definition's pattern captures, in order, read the way CucumberSwift reads it at run time.
struct StepPattern {
    /// One argument the closure receives.
    struct Capture: Equatable {
        /// The parameter's name in the expression, which is also its key path on `Match`: `int` for
        /// `{int}`, `anonymous` for `{}` and for a regular expression's capture group.
        let parameter: String
        /// The Swift type the parameter gives, for a built-in parameter. `nil` for a custom one, whose
        /// type the compiler checks against its `Match` extension.
        let type: String?
    }

    /// A mistake that means the pattern can never match.
    struct Problem: Error, Equatable {
        let message: String
        /// The pattern with the mistake corrected, when the correction is clear.
        let corrected: String?
    }

    static let builtInTypes = [
        "int": "Int",
        "float": "Float",
        "double": "Double",
        "string": "String",
        "word": "String",
        "anonymous": "String"
    ]

    let captures: [Capture]
    let isRegularExpression: Bool

    init(_ pattern: String) throws {
        isRegularExpression = Self.isRegularExpression(pattern)
        captures = isRegularExpression ? try Self.regularExpressionCaptures(pattern)
                                       : try Self.expressionCaptures(pattern)
    }

    /// The same rule as `CucumberExpression.init(_:)`.
    static func isRegularExpression(_ pattern: String) -> Bool {
        pattern.first == "^" || pattern.last == "$" || (pattern.count >= 2 && pattern.first == "/" && pattern.last == "/")
    }

    private static func regularExpressionCaptures(_ pattern: String) throws -> [Capture] {
        do {
            _ = try CucumberExpression(validating: pattern)
        } catch let error as InvalidRegularExpression {
            throw Problem(message: error.description, corrected: withoutRegularExpressionMarkers(pattern))
        }
        let compiled = pattern.first == "/" && pattern.last == "/" && pattern.count >= 2 ? String(pattern.dropFirst().dropLast()) : pattern
        // CucumberSwiftExpressions passes only top-level groups as arguments, so counting every group is
        // wrong for nested groups. cucumberswift/CucumberSwiftExpressions#67 makes the count public.
        let groups = (try? NSRegularExpression(pattern: compiled).numberOfCaptureGroups) ?? 0
        return Array(repeating: Capture(parameter: "anonymous", type: "String"), count: groups)
    }

    /// The pattern as a Cucumber Expression, when removing the anchors or slashes leaves a valid one.
    private static func withoutRegularExpressionMarkers(_ pattern: String) -> String? {
        var stripped = Substring(pattern)
        if stripped.count >= 2, stripped.first == "/", stripped.last == "/" {
            stripped = stripped.dropFirst().dropLast()
        } else {
            if stripped.first == "^" { stripped = stripped.dropFirst() }
            if stripped.last == "$" { stripped = stripped.dropLast() }
        }
        let candidate = String(stripped)
        guard !candidate.isEmpty, !isRegularExpression(candidate), (try? expressionCaptures(candidate)) != nil else { return nil }
        return candidate
    }

    // CucumberSwiftExpressions' lexer reports no errors, so this reads `{…}` itself until
    // cucumberswift/CucumberSwiftExpressions#67 reports syntax errors with their positions.
    private static func expressionCaptures(_ pattern: String) throws -> [Capture] {
        let characters = Array(pattern)
        var captures = [Capture]()
        var index = 0
        while index < characters.count {
            switch characters[index] {
                case "\\":
                    index += 2
                case "{":
                    guard let close = characters[(index + 1)...].firstIndex(of: "}") else {
                        throw unterminated(characters, open: index)
                    }
                    let name = String(characters[(index + 1)..<close])
                    let parameter = name.isEmpty ? "anonymous" : name
                    guard isIdentifier(parameter) else {
                        throw Problem(message: "The parameter type {\(name)} must be a Swift identifier, because the step definition reads it as \\.\(name) on Match.",
                                      corrected: nil)
                    }
                    captures.append(Capture(parameter: parameter, type: builtInTypes[parameter]))
                    index = close + 1
                default:
                    index += 1
            }
        }
        return captures
    }

    /// `{int cukes` most likely means `{int} cukes`, so the correction closes the parameter after its first word.
    private static func unterminated(_ characters: [Character], open: Int) -> Problem {
        let word = characters[(open + 1)...].prefix { !$0.isWhitespace }
        var corrected = characters
        corrected.insert("}", at: open + 1 + word.count)
        return Problem(message: "The parameter {\(String(word)) is missing its closing '}'.", corrected: String(corrected))
    }

    private static func isIdentifier(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first,
              first == "_" || CharacterSet.letters.contains(first) else { return false }
        return name.unicodeScalars.allSatisfy { $0 == "_" || CharacterSet.alphanumerics.contains($0) }
    }
}
