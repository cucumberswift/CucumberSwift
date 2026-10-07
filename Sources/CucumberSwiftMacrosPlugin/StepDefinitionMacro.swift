//
//  StepDefinitionMacro.swift
//  CucumberSwiftMacrosPlugin
//

#if Macros
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A step definition macro's arguments, checked against each other.
struct StepDefinition {
    /// One of the closure's parameters.
    struct Parameter {
        let name: String
        let type: TypeSyntax?
    }

    let literal: StringLiteralExprSyntax
    let pattern: StepPattern
    let closure: ClosureExprSyntax
    let parameters: [Parameter]
    /// The closure's last parameter, when it takes the `Step` after the arguments.
    let step: Parameter?

    init(_ node: some FreestandingMacroExpansionSyntax) throws {
        let arguments = Array(node.arguments)
        guard let first = arguments.first,
              let literal = first.expression.as(StringLiteralExprSyntax.self),
              let text = literal.representedLiteralValue else {
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: arguments.first.map { Syntax($0.expression) } ?? Syntax(node),
                           message: StepMessage.patternNotLiteral)
            ])
        }
        guard let closure = node.trailingClosure ?? arguments.dropFirst().first?.expression.as(ClosureExprSyntax.self) else {
            throw DiagnosticsError(diagnostics: [Diagnostic(node: Syntax(node), message: StepMessage.bodyNotClosure)])
        }
        self.literal = literal
        self.closure = closure

        do {
            pattern = try StepPattern(text)
        } catch let problem as StepPattern.Problem {
            throw DiagnosticsError(diagnostics: [Self.diagnostic(for: problem, in: literal)])
        }

        var parameters = Self.parameters(of: closure)
        if parameters.count == pattern.captures.count + 1, let last = parameters.last, Self.isStep(last) {
            step = parameters.removeLast()
        } else {
            step = nil
        }
        self.parameters = parameters

        let diagnostics = parameters.count == pattern.captures.count ? typeDiagnostics() : [arityDiagnostic()]
        if !diagnostics.isEmpty { throw DiagnosticsError(diagnostics: diagnostics) }
    }

    // MARK: Parameters

    private static func parameters(of closure: ClosureExprSyntax) -> [Parameter] {
        switch closure.signature?.parameterClause {
            case .simpleInput(let list):
                return list.map { Parameter(name: $0.name.text, type: nil) }
            case .parameterClause(let clause):
                return clause.parameters.map { Parameter(name: ($0.secondName ?? $0.firstName).text, type: $0.type) }
            case nil:
                return []
        }
    }

    private static func isStep(_ parameter: Parameter) -> Bool {
        guard let type = parameter.type?.trimmedDescription else { return parameter.name == "step" }
        return type == "Step" || type == "CucumberSwift.Step"
    }

    private static func unique(_ name: String, avoiding used: Set<String>) -> String {
        var candidate = name
        var number = 2
        while used.contains(candidate) {
            candidate = "\(name)\(number)"
            number += 1
        }
        return candidate
    }

    /// The closure's statements, moved to four spaces under the step definition.
    private static func reindented(_ statements: CodeBlockItemListSyntax) -> String {
        let lines = statements.description
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.allSatisfy(\.isWhitespace) ? "" : String($0) }
            .drop { $0.isEmpty }
            .reversed()
            .drop { $0.isEmpty }
            .reversed()
        let margin = lines.filter { !$0.isEmpty }.map { $0.prefix { $0 == " " }.count }.min() ?? 0
        return lines.map { $0.isEmpty ? "" : "    " + $0.dropFirst(margin) }.joined(separator: "\n")
    }

    /// Whether the closure, or a closure inside it, has a capture list.
    private static func hasCaptureList(_ closure: ClosureExprSyntax) -> Bool {
        closure.tokens(viewMode: .sourceAccurate).contains { $0.parent?.is(ClosureCaptureClauseSyntax.self) == true }
    }

    /// Whether the closure's own body awaits, which makes Swift infer that it is async, without the keyword.
    private static func awaits(_ closure: ClosureExprSyntax) -> Bool {
        final class Finder: SyntaxVisitor {
            var found = false
            // An await in a nested closure or function makes only that one async.
            override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
            override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
            override func visit(_: AwaitExprSyntax) -> SyntaxVisitorContinueKind {
                found = true
                return .skipChildren
            }
            override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
                if node.awaitKeyword != nil { found = true }
                return .visitChildren
            }
        }
        let finder = Finder(viewMode: .sourceAccurate)
        finder.walk(closure.statements)
        return finder.found
    }

    // MARK: Diagnostics

    private static func diagnostic(for problem: StepPattern.Problem, in literal: StringLiteralExprSyntax) -> Diagnostic {
        let fixIts = problem.corrected.flatMap { corrected -> FixIt? in
            // Rewriting the literal keeps a plain one-line string exact; leave raw and multi-line strings alone.
            guard literal.openingPounds == nil, literal.openingQuote.tokenKind == .stringQuote else { return nil }
            let message = StepPattern.isRegularExpression(literal.representedLiteralValue ?? "")
                ? StepFixItMessage.removeRegularExpressionMarkers
                : StepFixItMessage.closeParameter
            return FixIt(message: message,
                         changes: [.replace(oldNode: Syntax(literal), newNode: Syntax(StringLiteralExprSyntax(content: corrected)))])
        }
        return Diagnostic(node: Syntax(literal), message: StepMessage.invalidPattern(problem.message), fixIts: fixIts.map { [$0] } ?? [])
    }

    /// The step definition a user would write by hand.
    func expansion(keyword: String) -> ExprSyntax {
        let used = Set(parameters.map(\.name) + [step?.name].compactMap { $0 })
        let match = pattern.captures.isEmpty ? "_" : Self.unique("match", avoiding: used)
        let stepName = step?.name ?? "_"

        var countByParameter = [String: Int]()
        for capture in pattern.captures { countByParameter[capture.parameter, default: 0] += 1 }
        var indexByParameter = [String: Int]()
        var bindings = [String]()
        for (capture, parameter) in zip(pattern.captures, parameters) {
            let index = indexByParameter[capture.parameter, default: 0]
            indexByParameter[capture.parameter] = index + 1
            // The same accessors as the step definitions CucumberSwift suggests for undefined steps.
            let value = countByParameter[capture.parameter] == 1
                ? "try \(match).first(\\.\(capture.parameter))"
                : "\(match)[\\.\(capture.parameter), index: \(index)]"
            guard parameter.name != "_" else { continue }
            let type = parameter.type.map { ": \($0.trimmedDescription)" } ?? ""
            bindings.append("let \(parameter.name)\(type) = \(value)")
        }

        let signature = closure.signature
        let attributes = signature?.attributes.map { "\($0.trimmedDescription) " }.joined() ?? ""
        let captureList = signature?.capture.map { "\($0.trimmedDescription) " } ?? ""
        // The expansion reads its arguments with `try`. Swift infers `throws` for a closure that
        // writes no effects, but not for one that writes `async` alone, so add it there.
        var effects = signature?.effectSpecifiers?.trimmedDescription ?? ""
        if signature?.effectSpecifiers?.asyncSpecifier != nil, signature?.effectSpecifiers?.throwsClause == nil {
            effects += " throws"
        }
        let arguments = effects.isEmpty ? "\(match), \(stepName)" : "(\(match), \(stepName)) \(effects)"
        let body = (bindings.map { "    \($0)" } + [Self.reindented(closure.statements)]).filter { !$0.isEmpty }
        let opening = "{ \(attributes)\(captureList)\(arguments) in"

        guard Self.hasCaptureList(closure) else {
            return """
            \(raw: keyword)(\(literal.trimmed) as CucumberExpression) \(raw: opening)
            \(raw: body.joined(separator: "\n"))
            }
            """
        }
        // Swift fails to type-check a closure with a capture list, its own or a nested closure's, when
        // it is an argument to the step definition in a macro's expansion, although the same call
        // compiles written by hand. Typed as a constant first, it compiles.
        // The step definitions take an async closure on the main actor, as when it is passed directly.
        let isAsync = signature?.effectSpecifiers?.asyncSpecifier != nil || Self.awaits(closure)
        let isolation = isAsync || attributes.contains("@MainActor") ? "@MainActor " : ""
        let type = "\(isolation)(CucumberSwiftExpressions.Match, Step) \(isAsync ? "async " : "")throws -> Void"
        let constant = Self.unique("callback", avoiding: Set(closure.tokens(viewMode: .sourceAccurate).map(\.text)))
        let indented = body.joined(separator: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.isEmpty ? "" : "    \($0)" }
        return """
        { () -> \(raw: keyword) in
            let \(raw: constant): \(raw: type) = \(raw: opening)
        \(raw: indented.joined(separator: "\n"))
            }
            return \(raw: keyword)(\(literal.trimmed) as CucumberExpression, callback: \(raw: constant))
        }()
        """
    }

    private func arityDiagnostic() -> Diagnostic {
        var names = Set<String>()
        let expected = pattern.captures.enumerated().map { index, capture -> String in
            let existing = index < parameters.count ? parameters[index] : nil
            let name = existing?.name ?? Self.unique(capture.parameter == "anonymous" ? "group" : capture.parameter, avoiding: names)
            names.insert(name)
            let type = existing?.type?.trimmedDescription ?? capture.type ?? "<#\(capture.parameter) output#>"
            return "\(name): \(type)"
        } + [step.map { "\($0.name): \($0.type?.trimmedDescription ?? "Step")" }].compactMap { $0 }

        let clause = "(\(expected.joined(separator: ", ")))"
        // Parse the new parameters as part of a closure, the only place the parser accepts them.
        let message = StepMessage.wrongArity(expected: pattern.captures.count,
                                             actual: parameters.count,
                                             isRegularExpression: pattern.isRegularExpression)
        guard let parsed = ExprSyntax("{ \(raw: clause) in }").as(ClosureExprSyntax.self)?.signature else {
            return Diagnostic(node: Syntax(closure), message: message)
        }
        let change: FixIt.Change
        if let signature = closure.signature {
            // A signature without parameters, such as `[weak self] in`, gets them before `in`.
            let existing = signature.parameterClause
            let clause = parsed.parameterClause?
                .with(\.leadingTrivia, existing?.leadingTrivia ?? (signature.capture == nil ? [] : .space))
                .with(\.trailingTrivia, existing?.trailingTrivia ?? .space)
            change = .replace(oldNode: Syntax(signature), newNode: Syntax(signature.with(\.parameterClause, clause)))
        } else {
            let signature = parsed.with(\.leadingTrivia, []).with(\.trailingTrivia, closure.statements.isEmpty ? .space : [])
            change = .replace(oldNode: Syntax(closure), newNode: Syntax(closure.with(\.signature, signature)))
        }

        let fixIt = FixIt(message: StepFixItMessage.matchParameters(clause), changes: [change])
        return Diagnostic(node: closure.signature.map { Syntax($0) } ?? Syntax(closure.leftBrace),
                          message: message,
                          fixIts: [fixIt])
    }

    private func typeDiagnostics() -> [Diagnostic] {
        zip(pattern.captures, parameters).compactMap { capture, parameter in
            guard let expected = capture.type, let type = parameter.type,
                  type.trimmedDescription != expected, type.trimmedDescription != "Swift.\(expected)" else { return nil }
            let replacement = TypeSyntax(IdentifierTypeSyntax(name: .identifier(expected)))
                .with(\.leadingTrivia, type.leadingTrivia)
                .with(\.trailingTrivia, type.trailingTrivia)
            let message = StepMessage.wrongType(parameter: capture.parameter,
                                                expected: expected,
                                                name: parameter.name,
                                                actual: type.trimmedDescription)
            let fixIt = FixIt(message: StepFixItMessage.changeType(expected),
                              changes: [.replace(oldNode: Syntax(type), newNode: Syntax(replacement))])
            return Diagnostic(node: Syntax(type), message: message, fixIts: [fixIt])
        }
    }
}

enum StepMessage: DiagnosticMessage {
    case patternNotLiteral
    case bodyNotClosure
    case invalidPattern(String)
    case wrongArity(expected: Int, actual: Int, isRegularExpression: Bool)
    case wrongType(parameter: String, expected: String, name: String, actual: String)

    var message: String {
        switch self {
            case .patternNotLiteral:
                return "The step definition's pattern must be a string literal, so it can be checked when it compiles."
            case .bodyNotClosure:
                return "The step definition's body must be a closure."
            case .invalidPattern(let problem):
                return problem
            case let .wrongArity(expected, actual, isRegularExpression):
                let what = isRegularExpression ? "capture group" : "parameter"
                return "The pattern has \(expected) \(what)\(expected == 1 ? "" : "s"), but the closure takes \(actual) argument\(actual == 1 ? "" : "s"). "
                    + "Give the closure one argument per \(what), in order, optionally followed by the Step."
            case let .wrongType(parameter, expected, name, actual):
                let source = parameter == "anonymous" ? "A capture group" : "{\(parameter)}"
                return "\(source) gives \(expected), but '\(name)' is declared as \(actual)."
        }
    }

    var diagnosticID: MessageID {
        switch self {
            case .patternNotLiteral: return MessageID(domain: "CucumberSwiftMacros", id: "patternNotLiteral")
            case .bodyNotClosure: return MessageID(domain: "CucumberSwiftMacros", id: "bodyNotClosure")
            case .invalidPattern: return MessageID(domain: "CucumberSwiftMacros", id: "invalidPattern")
            case .wrongArity: return MessageID(domain: "CucumberSwiftMacros", id: "wrongArity")
            case .wrongType: return MessageID(domain: "CucumberSwiftMacros", id: "wrongType")
        }
    }

    var severity: DiagnosticSeverity { .error }
}

enum StepFixItMessage: FixItMessage {
    case closeParameter
    case removeRegularExpressionMarkers
    case matchParameters(String)
    case changeType(String)

    var message: String {
        switch self {
            case .closeParameter: return "Insert '}'"
            case .removeRegularExpressionMarkers: return "Use it as a Cucumber Expression"
            case .matchParameters(let clause): return "Change the closure's parameters to \(clause)"
            case .changeType(let type): return "Change the type to \(type)"
        }
    }

    var fixItID: MessageID {
        switch self {
            case .closeParameter: return MessageID(domain: "CucumberSwiftMacros", id: "closeParameter")
            case .removeRegularExpressionMarkers: return MessageID(domain: "CucumberSwiftMacros", id: "removeRegularExpressionMarkers")
            case .matchParameters: return MessageID(domain: "CucumberSwiftMacros", id: "matchParameters")
            case .changeType: return MessageID(domain: "CucumberSwiftMacros", id: "changeType")
        }
    }
}

/// Every step definition macro: `#Given`, `#When`, `#Then`, `#And`, `#But`, `#MatchAll` and each
/// localized name, such as `#ES_Dado`. The macro's own name is the step type it expands to, so
/// `#ES_Dado(…)` becomes `ES_Dado(…)`.
public struct StepDefinitionMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in _: some MacroExpansionContext) throws -> ExprSyntax {
        try StepDefinition(node).expansion(keyword: node.macroName.text)
    }
}
#endif
