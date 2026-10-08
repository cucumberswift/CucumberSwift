//
//  StepDefinitionCall.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

/// One step definition call, checked and converted. The reads and the rewriting are in extensions.
struct StepDefinitionCall {
    /// What a read statement reads: the parameter's key path, and its index when it reads by position.
    struct Source {
        let name: String
        let type: TypeSyntax?
        let parameter: String
        let index: Int?
    }

    /// A parameter read at the top of the closure: `let count: Int = try match.first(\.int)`.
    struct Read {
        let name: String
        let type: TypeSyntax?
        let capture: Int
    }

    struct Parameter {
        let name: String
        let type: TypeSyntax?
    }

    /// The step definition's arguments, checked.
    struct Arguments {
        let pattern: StepPattern
        let closure: ClosureExprSyntax
        /// The string regular expression that replaces a regex literal, or `nil` for a pattern that is a string already.
        let replacement: StringLiteralExprSyntax?
    }

    let call: FunctionCallExprSyntax
    let keyword: String
    let runner: Runner

    init(_ call: FunctionCallExprSyntax, keyword: String, runner: Runner) {
        self.call = call
        self.keyword = keyword
        self.runner = runner
    }

    func macro() throws -> MacroExpansionExprSyntax {
        guard let found = runner.found else { throw Unconvertible(reason: runner.problem ?? "") }
        if StepDefinitionConverter.localizedNames.contains(keyword), !found.hasLocalizedMacros {
            throw Unconvertible(reason: "\(found.macrosModule) has no localized macros")
        }
        let arguments = try arguments()
        let (pattern, closure) = (arguments.pattern, arguments.closure)
        let isRegexLiteral = arguments.replacement != nil
        let parameters = try closureParameters(closure)
        let reads = isRegexLiteral
            ? try regexReads(in: closure, match: parameters.match, pattern: pattern)
            : try self.reads(in: closure, match: parameters.match, pattern: pattern)
        let rest = closure.statements.dropFirst(reads.count)
        try checkTheRest(rest, match: parameters.match, isRegexLiteral: isRegexLiteral)

        var clause = [String]()
        var names = [String]()
        for (index, capture) in pattern.captures.enumerated() {
            let read = reads.first { $0.capture == index }
            let name = read?.name ?? "_"
            guard let type = try parameterType(of: read, capture: capture) else {
                throw Unconvertible(reason: "it doesn't read {\(capture.parameter)}, a custom parameter type, so the macro's closure can't be given its type")
            }
            clause.append("\(name): \(type)")
            names.append(name)
        }
        if parameters.step.name != "_" {
            clause.append("\(parameters.step.name): \(parameters.step.type?.trimmedDescription ?? "Step")")
            names.append(parameters.step.name)
        }
        // The expansion names the Match `match`, or `match2` and so on when a parameter has that name.
        var hidden = "match"
        var number = 2
        while names.contains(hidden) {
            hidden = "match\(number)"
            number += 1
        }
        if !pattern.captures.isEmpty, Self.references(hidden, in: rest) {
            throw Unconvertible(reason: "its closure uses `\(hidden)`, which the macro's expansion would hide behind its own `\(hidden)`")
        }

        let newClosure = try rewritten(closure, parameters: clause, droppingReads: reads.count)
        return makeMacro(closure: newClosure, pattern: arguments.replacement)
    }

    // MARK: Arguments

    private func arguments() throws -> Arguments {
        let arguments = Array(call.arguments)
        let labels = arguments.dropFirst().compactMap { $0.label?.text }
        if labels.contains("class") {
            throw Unconvertible(reason: "it calls a selector, and the macros take a closure")
        }
        if let other = labels.first(where: { $0 != "callback" }) {
            throw Unconvertible(reason: "it passes `\(other):`, which the macros don't take")
        }
        let expression = arguments[0].expression
        var replacement: StringLiteralExprSyntax?
        let text: String
        if let regex = expression.as(RegexLiteralExprSyntax.self) {
            // The macros take a string, so a regex literal becomes the string regular expression CucumberSwift also reads.
            let string = try RegexLiteralPattern.stringLiteral(for: regex)
            replacement = string
            text = string.representedLiteralValue ?? ""
        } else if let literal = expression.as(StringLiteralExprSyntax.self), let value = literal.representedLiteralValue {
            text = value
        } else {
            throw Unconvertible(reason: "its pattern isn't a string literal")
        }
        let pattern: StepPattern
        do {
            pattern = try StepPattern(text)
        } catch let problem as StepPattern.Problem {
            throw Unconvertible(reason: "its pattern has a mistake the macro would report: \(problem.message)")
        }
        let body = call.trailingClosure.map { ExprSyntax($0) } ?? arguments.dropFirst().first?.expression
        guard let closure = body?.as(ClosureExprSyntax.self), call.additionalTrailingClosures.isEmpty else {
            throw Unconvertible(reason: "it passes a function, and the macros take a closure")
        }
        return Arguments(pattern: pattern, closure: closure, replacement: replacement)
    }

    // MARK: The closure's parameters

    private func closureParameters(_ closure: ClosureExprSyntax) throws -> (match: Parameter, step: Parameter) {
        let parameters: [Parameter]
        switch closure.signature?.parameterClause {
            case .simpleInput(let list):
                parameters = list.map { Parameter(name: $0.name.text, type: nil) }
            case .parameterClause(let clause):
                parameters = clause.parameters.map { Parameter(name: ($0.secondName ?? $0.firstName).text, type: $0.type) }
            case nil:
                throw Unconvertible(reason: "its closure uses $0 and $1, and the macros name each argument")
        }
        guard parameters.count == 2 else {
            throw Unconvertible(reason: "its closure doesn't take a Match and a Step")
        }
        if let type = parameters[0].type?.trimmedDescription, type != "Match", type != "CucumberSwiftExpressions.Match" {
            throw Unconvertible(reason: type.replacingOccurrences(of: " ", with: "") == "[String]"
                ? "it uses the deprecated [String] closure"
                : "its closure's first argument is \(type), not a Match")
        }
        return (parameters[0], parameters[1])
    }
}
#endif
