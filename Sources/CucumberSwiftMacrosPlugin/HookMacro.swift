//
//  HookMacro.swift
//  CucumberSwiftMacrosPlugin
//

#if Macros
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A hook macro's closure, checked against what the hook passes it.
struct HookDefinition {
    /// What each hook passes its closure.
    static let argumentTypes = [
        "BeforeFeature": "Feature",
        "AfterFeature": "Feature",
        "BeforeScenario": "Scenario",
        "AfterScenario": "Scenario",
        "BeforeStep": "Step",
        "AfterStep": "Step"
    ]

    let hook: String
    /// `Feature`, `Scenario` or `Step`.
    let argumentType: String
    let closure: ClosureExprSyntax
    let parameters: [StepDefinition.Parameter]

    init(_ node: some FreestandingMacroExpansionSyntax) throws {
        hook = node.macroName.text
        argumentType = Self.argumentTypes[hook] ?? "Scenario"
        let body = node.trailingClosure.map { ExprSyntax($0) }
            ?? node.arguments.first { $0.label?.text == "closure" }?.expression
        guard let closure = body?.as(ClosureExprSyntax.self), node.additionalTrailingClosures.isEmpty else {
            throw DiagnosticsError(diagnostics: [Diagnostic(node: Syntax(node), message: HookMessage.bodyNotClosure)])
        }
        self.closure = closure
        parameters = StepDefinition.parameters(of: closure)
        if parameters.count > 1 { throw DiagnosticsError(diagnostics: [arityDiagnostic()]) }
        if let diagnostic = typeDiagnostic() { throw DiagnosticsError(diagnostics: [diagnostic]) }
    }

    /// The hook call a user would write by hand: the same arguments, and the closure, given `_` when it takes no argument.
    func expansion(of node: some FreestandingMacroExpansionSyntax) -> ExprSyntax {
        let closure = withArgument(closure)
        var arguments = Array(node.arguments)
        if let index = arguments.firstIndex(where: { $0.label?.text == "closure" }) {
            arguments[index] = arguments[index].with(\.expression, ExprSyntax(closure))
        }
        // The macro's own tokens, so the call keeps the spacing as written: `#BeforeScenario {` is `BeforeScenario {`.
        let call = FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: node.macroName.with(\.leadingTrivia, [])),
            leftParen: node.leftParen,
            arguments: LabeledExprListSyntax(arguments),
            rightParen: node.rightParen,
            trailingClosure: node.trailingClosure == nil ? nil : closure)
        return ExprSyntax(call)
    }

    /// The closure, with `_` for the hook's argument when it takes none and doesn't use `$0`.
    private func withArgument(_ closure: ClosureExprSyntax) -> ClosureExprSyntax {
        guard parameters.isEmpty, !Self.usesAnonymousArgument(closure) else { return closure }
        let wildcard = ClosureShorthandParameterListSyntax([ClosureShorthandParameterSyntax(name: .wildcardToken())])
        if let signature = closure.signature {
            // `{ [weak self] in` becomes `{ [weak self] _ in`, and `{ () async in` becomes `{ _ async in`.
            let clause = ClosureSignatureSyntax.ParameterClause.simpleInput(wildcard.with(\.trailingTrivia, .space))
            return closure.with(\.signature, signature.with(\.parameterClause, clause))
        }
        let startsOnNewLine = closure.statements.first?.leadingTrivia.contains { $0.isNewline } ?? false
        let signature = ClosureSignatureSyntax(
            parameterClause: .simpleInput(wildcard),
            inKeyword: .keyword(.in, leadingTrivia: .space, trailingTrivia: startsOnNewLine ? [] : .space))
        return closure
            .with(\.leftBrace, closure.leftBrace.with(\.trailingTrivia, .space))
            .with(\.signature, signature)
            .with(\.statements, closure.statements.with(\.leadingTrivia, startsOnNewLine ? closure.statements.leadingTrivia : []))
    }

    /// Whether the closure's own body uses `$0`, which takes the hook's argument without a parameter.
    private static func usesAnonymousArgument(_ closure: ClosureExprSyntax) -> Bool {
        StepDefinition.BodyFinder.contains(in: closure) { node in
            if case .dollarIdentifier = node.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind { return true }
            return false
        }
    }

    // MARK: Diagnostics

    private func isArgumentType(_ type: TypeSyntax) -> Bool {
        let written = type.trimmedDescription
        return [argumentType, "CucumberSwift.\(argumentType)", "CucumberSwiftTesting.\(argumentType)"].contains(written)
    }

    private func arityDiagnostic() -> Diagnostic {
        let name = parameters.first.map(\.name) ?? argumentType.lowercased()
        let clause = "(\(name): \(argumentType))"
        let message = HookMessage.wrongArity(hook: hook, type: argumentType, actual: parameters.count)
        guard let signature = closure.signature,
              let parsed = ExprSyntax("{ \(raw: clause) in }").as(ClosureExprSyntax.self)?.signature?.parameterClause else {
            return Diagnostic(node: Syntax(closure), message: message)
        }
        let existing = signature.parameterClause
        let replacement = parsed
            .with(\.leadingTrivia, existing?.leadingTrivia ?? [])
            .with(\.trailingTrivia, existing?.trailingTrivia ?? .space)
        let fixIt = FixIt(message: StepFixItMessage.matchParameters(clause),
                          changes: [.replace(oldNode: Syntax(signature), newNode: Syntax(signature.with(\.parameterClause, replacement)))])
        return Diagnostic(node: Syntax(signature), message: message, fixIts: [fixIt])
    }

    private func typeDiagnostic() -> Diagnostic? {
        guard let parameter = parameters.first, let type = parameter.type, !isArgumentType(type) else { return nil }
        let replacement = TypeSyntax(IdentifierTypeSyntax(name: .identifier(argumentType)))
            .with(\.leadingTrivia, type.leadingTrivia)
            .with(\.trailingTrivia, type.trailingTrivia)
        let message = HookMessage.wrongType(hook: hook, expected: argumentType, name: parameter.name, actual: type.trimmedDescription)
        let fixIt = FixIt(message: StepFixItMessage.changeType(argumentType),
                          changes: [.replace(oldNode: Syntax(type), newNode: Syntax(replacement))])
        return Diagnostic(node: Syntax(type), message: message, fixIts: [fixIt])
    }
}

enum HookMessage: DiagnosticMessage {
    case bodyNotClosure
    case wrongArity(hook: String, type: String, actual: Int)
    case wrongType(hook: String, expected: String, name: String, actual: String)

    var message: String {
        switch self {
            case .bodyNotClosure:
                return "The hook's body must be a closure."
            case let .wrongArity(hook, type, actual):
                return "\(hook) passes the \(type), but the closure takes \(actual) arguments. "
                    + "Give the closure one argument, the \(type), or none."
            case let .wrongType(hook, expected, name, actual):
                return "\(hook) passes a \(expected), but '\(name)' is declared as \(actual)."
        }
    }

    var diagnosticID: MessageID {
        switch self {
            case .bodyNotClosure: return MessageID(domain: "CucumberSwiftMacros", id: "hookBodyNotClosure")
            case .wrongArity: return MessageID(domain: "CucumberSwiftMacros", id: "hookWrongArity")
            case .wrongType: return MessageID(domain: "CucumberSwiftMacros", id: "hookWrongType")
        }
    }

    var severity: DiagnosticSeverity { .error }
}

/// Every hook macro: `#BeforeFeature`, `#AfterFeature`, `#BeforeScenario`, `#AfterScenario`, `#BeforeStep` and
/// `#AfterStep`. The macro's own name is the hook it expands to, so `#BeforeScenario { … }` becomes
/// `BeforeScenario { … }`, with the same arguments.
public struct HookMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in _: some MacroExpansionContext) throws -> ExprSyntax {
        try HookDefinition(node).expansion(of: node)
    }
}
#endif
