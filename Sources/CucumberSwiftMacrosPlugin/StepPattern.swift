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
        let syntax: CucumberExpression.Syntax
        do {
            syntax = try CucumberExpression.Syntax(parsing: pattern)
        } catch let error as InvalidRegularExpression {
            throw Problem(message: error.description, corrected: Self.withoutRegularExpressionMarkers(pattern))
        } catch let error as CucumberExpression.SyntaxError {
            throw Problem(message: "\(error.message). \(error.solution)", corrected: Self.correction(for: error))
        }
        isRegularExpression = syntax.kind == .regularExpression
        captures = try syntax.arguments.map { argument in
            let parameter = argument.parameterName.isEmpty ? "anonymous" : argument.parameterName
            guard Self.isIdentifier(parameter) else {
                throw Problem(message: "The parameter type {\(parameter)} must be a Swift identifier, because the step definition reads it as \\.\(parameter) on Match.",
                              corrected: nil)
            }
            return Capture(parameter: parameter, type: Self.builtInTypes[parameter])
        }
    }

    /// The same rule as `CucumberExpression.init(_:)`.
    static func isRegularExpression(_ pattern: String) -> Bool {
        pattern.first == "^" || pattern.last == "$" || (pattern.count >= 2 && pattern.first == "/" && pattern.last == "/")
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
        guard !candidate.isEmpty,
              let syntax = try? CucumberExpression.Syntax(parsing: candidate),
              syntax.kind == .cucumberExpression else { return nil }
        return candidate
    }

    /// The fix for a syntax error, when it is clear. `{int cukes` most likely means `{int} cukes`, so a
    /// missing `}` goes after the first word of the parameter's name.
    private static func correction(for error: CucumberExpression.SyntaxError) -> String? {
        guard error.problem == .missingClosingBrace else { return nil }
        let expression = error.expression
        let name = expression[error.range.upperBound...].prefix { !$0.isWhitespace }
        var corrected = expression
        corrected.insert("}", at: name.endIndex)
        guard (try? CucumberExpression.Syntax(parsing: corrected)) != nil else { return nil }
        return corrected
    }

    private static func isIdentifier(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first,
              first == "_" || CharacterSet.letters.contains(first) else { return false }
        return name.unicodeScalars.allSatisfy { $0 == "_" || CharacterSet.alphanumerics.contains($0) }
    }
}
