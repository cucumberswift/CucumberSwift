//
//  StubGenerator.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/4/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
enum StubGenerator {
    /// How the generated step definitions match their steps.
    enum Style: Equatable {
        /// `Then("I see {int} messages") { match, _ in … }`, on every deployment target. The default.
        case cucumberExpression
        /// `Then(#/^I see (\d+) messages$/#) { matches, _ in … }`, with ``Cucumber/generateRegexLiterals``.
        case regexLiteral(RegexLiteralStyle)
    }

    static var implementorRegexLiteralStyle: RegexLiteralStyle {
        (Cucumber.shared as? StepImplementation)?.regexLiteralStyle ?? .extendedDelimiter
    }

    static var implementorStyle: Style {
        FeatureFlags.isGenerateRegexLiterals ? .regexLiteral(implementorRegexLiteralStyle) : .cucumberExpression
    }

    private static func regexForTokens(_ tokens: [Token]) -> String {
        var regex = ""
        for token in tokens {
            if case .match(let m) = token {
                regex += NSRegularExpression
                    .escapedPattern(for: m)
            } else if case .string = token {
                regex += "\\\"(.*?)\\\""
            } else if case .int = token {
                regex += "(\\d+)"
            }
        }
        return regex.trimmingCharacters(in: .whitespaces)
    }

    /// Reads `5.25` as one number, and a `-` straight before a number, after a space or at the start, as its sign.
    private static func expressionTokens(_ tokens: [Token]) -> [Token] {
        var result = [Token]()
        var index = tokens.startIndex
        while index < tokens.endIndex {
            if case .int(let whole) = tokens[index],
               index + 2 < tokens.endIndex,
               case .match(".") = tokens[index + 1],
               case .int(let fraction) = tokens[index + 2] {
                result.append(.float(value: "\(whole).\(fraction)"))
                index += 3
            } else {
                result.append(tokens[index])
                index += 1
            }
        }
        for (position, token) in result.enumerated() where position + 1 < result.endIndex {
            guard case .match(let text) = token, text.hasSuffix("-") else { continue }
            let rest = text.dropLast()
            guard rest.isEmpty || rest.last?.isWhitespace == true else { continue }
            switch result[position + 1] {
                case .int(let value): result[position + 1] = .int(value: "-\(value)")
                case .float(let value): result[position + 1] = .float(value: "-\(value)")
                default: continue
            }
            result[position] = .match(value: String(rest))
        }
        return result.filter {
            if case .match("") = $0 { return false }
            return true
        }
    }

    /// The step as a Cucumber Expression. `(`, `{`, `/` and `\` would otherwise start an optional, a
    /// parameter, an alternative or an escape, and a leading `^` would make the pattern a regular expression.
    private static func expression(for tokens: [Token]) -> String {
        var expression = tokens.map { token -> String in
            switch token {
                case .match(let text):
                    return text.reduce(into: "") { escaped, character in
                        if "\\({/".contains(character) { escaped.append("\\") }
                        escaped.append(character)
                    }
                case .string: return "{string}"
                case .int: return "{int}"
                case .float: return "{float}"
            }
        }
        .joined()
        .trimmingCharacters(in: .whitespaces)
        if expression.hasPrefix("^") {
            expression = "\\" + expression
        }
        return expression
    }

    /// `text` as a Swift string literal.
    private static func swiftStringLiteral(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private struct Definition {
        let pattern: String
        let matchesParameter: String
        let captures: [(type: String, value: String)]
    }

    private static func regexLiteralDefinition(regex: String, tokens: [Token], style: RegexLiteralStyle) -> Definition {
        let pattern = "^\(regex)$"
        // The pattern escapes every `/`, so neither delimiter can end the literal early.
        let literal: String
        switch style {
            case .bareSlash: literal = "/\(pattern)/"
            case .extendedDelimiter: literal = "#/\(pattern)/#"
        }
        // In the order the regular expression captures them.
        let types = tokens.compactMap { token -> String? in
            if token.isString() { return "string" }
            if token.isInteger() { return "integer" }
            return nil
        }
        // A regex literal's match holds the whole match at .0 and each capture at .1, .2, …
        let captures = types.enumerated().map { (type: $1, value: "matches.\($0 + 1)") }
        return Definition(pattern: literal, matchesParameter: captures.isEmpty ? "_" : "matches", captures: captures)
    }

    private static func cucumberExpressionDefinition(regex: String, tokens: [Token]) -> Definition {
        let expression = expression(for: expressionTokens(tokens))
        guard !expression.hasSuffix("$") else {
            // A pattern that ends in `$` is always a regular expression, so the step can't be a Cucumber
            // Expression. An anchored string is a regular expression on every deployment target, and
            // each of its capture groups, one for each string and number in `regex`, is an anonymous parameter.
            let captureCount = tokens.filter { $0.isString() || $0.isInteger() }.count
            let captures = (0..<captureCount).map { (type: "string", value: "match[\\.anonymous, index: \($0)]") }
            return Definition(pattern: swiftStringLiteral("^\(regex)$"),
                              matchesParameter: captures.isEmpty ? "_" : "match",
                              captures: captures)
        }
        let types = expressionTokens(tokens).compactMap { token -> String? in
            switch token {
                case .string: return "string"
                case .int: return "int"
                case .float: return "float"
                case .match: return nil
            }
        }
        var countByType = [String: Int]()
        types.forEach { countByType[$0, default: 0] += 1 }
        var indexByType = [String: Int]()
        let captures = types.map { type -> (type: String, value: String) in
            let index = indexByType[type, default: 0]
            indexByType[type] = index + 1
            let value = countByType[type] == 1 ? "try match.first(\\.\(type))" : "match[\\.\(type), index: \(index)]"
            return (type: type, value: value)
        }
        return Definition(pattern: swiftStringLiteral(expression),
                          matchesParameter: captures.isEmpty ? "_" : "match",
                          captures: captures)
    }

    static func getStubs(for features: [Feature],
                         style: Style = implementorStyle) -> [(step: Step, generatedSwift: String)] {
        var lookup = [String: Method]()
        let executableSteps = features
            .taggedElements(askImplementor: false)
            .flatMap { $0.scenarios }
            .taggedElements(askImplementor: true)
            .flatMap { $0.steps }
            .sorted { $0.keyword.rawValue < $1.keyword.rawValue }

        let implementedSteps = executableSteps.filter { $0.canExecute }

        let methods = executableSteps
            .filter { !$0.canExecute }
            .reduce(into: [(step: Step, method: Method)]()) {
                let tokens = StubGenerator.Lexer($1.match).lex()
                let regex = regexForTokens(tokens)
                let definition: Definition
                switch style {
                    case .cucumberExpression: definition = cucumberExpressionDefinition(regex: regex, tokens: tokens)
                    case .regexLiteral(let regexLiteralStyle):
                        definition = regexLiteralDefinition(regex: regex, tokens: tokens, style: regexLiteralStyle)
                }
                let variables = [
                    (type: "dataTable", count: $1.dataTable != nil ? 1 : 0),
                    (type: "docString", count: $1.docString != nil ? 1 : 0)
                ]

                // Steps that differ only in their parameters, such as `5` and `-5`, share a step definition.
                if let m = lookup[definition.pattern],
                   !m.keyword.contains($1.keyword) {
                    m.insertKeyword($1.keyword)
                } else {
                    let method = Method(keyword: $1.keyword,
                                        pattern: definition.pattern,
                                        regex: regex,
                                        matchesParameter: definition.matchesParameter,
                                        captures: definition.captures,
                                        variables: variables)
                    $0.append(($1, method))
                    lookup[definition.pattern] = method
                }
            }

        return methods.map { step, method in
            let canMatchAll = implementedSteps.allSatisfy { $0.match.matches(for: method.regex).isEmpty }
            let overwrittenSteps = implementedSteps.filter { method.keyword.contains($0.keyword) && !$0.match.matches(for: method.regex).isEmpty }
            if !overwrittenSteps.isEmpty {
                method.comment = "//FIXME: WARNING: This will overwite your implementation for the step(s):\n"
                method.comment += overwrittenSteps.map { "//                \($0.keyword.toString()) \($0.match)" }.joined(separator: "\n")
                method.comment += "\n"
            }
            return (step, method.generateSwift(matchAllAllowed: canMatchAll))
        }
    }
}
