//
//  DSLStepMacro.swift
//  CucumberSwiftMacrosPlugin
//

#if Macros
import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// What the DSL step macros report.
enum DSLStepMessage: String, DiagnosticMessage {
    case oneArgument

    var message: String {
        switch self {
            case .oneArgument:
                "A step takes one argument: what it runs, such as `#Given(I: logIn())`, an async function, or a closure."
        }
    }

    var diagnosticID: MessageID { MessageID(domain: "CucumberSwiftMacros", id: rawValue) }
    var severity: DiagnosticSeverity { .error }
}

/// A step of a feature written in the Swift DSL, with its text captured when it compiles: `#Given(I: logIn())`
/// expands to `Given(_macroStep: logIn(), stepText: "I: logIn()", line: …, column: …, file: …)`. The function
/// form, `Given(I: logIn())`, reads the same text from the Swift file when the tests run, which fails on a
/// device or from an archived test bundle.
public struct DSLStepMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in context: some MacroExpansionContext) throws -> ExprSyntax {
        guard let argument = node.arguments.first, node.arguments.count == 1, node.trailingClosure == nil else {
            throw DiagnosticsError(diagnostics: [Diagnostic(node: Syntax(node), message: DSLStepMessage.oneArgument)])
        }
        let expression = argument.expression.trimmed
        // As the function form's text: the label and what is after it, such as `I: logIn()`.
        let stepText = (argument.label.map { "\($0.text): " } ?? "") + text(of: expression)
        // The function form's `#line` and `#column` are those of the opening parenthesis.
        let anchor = node.leftParen.map { Syntax($0) } ?? Syntax(node)
        let location = context.location(of: anchor, at: .afterLeadingTrivia, filePathMode: .filePath)
        let line = location?.line ?? "#line"
        let column = location?.column ?? "#column"
        let file = location?.file ?? "#filePath"
        let keyword = node.macroName.with(\.leadingTrivia, []).with(\.trailingTrivia, [])
        return "\(keyword)(_macroStep: \(expression), stepText: \(literal: stepText), line: \(line), column: \(column), file: \(file))"
    }

    /// The expression as written, with each run of spaces, line breaks and comments between its tokens made one
    /// space, and none just inside parentheses and brackets or before a comma, so that a call written over
    /// several lines reads as it would on one.
    static func text(of expression: ExprSyntax) -> String {
        var text = ""
        var previous: TokenSyntax?
        for token in expression.tokens(viewMode: .sourceAccurate) {
            if let previous, !previous.trailingTrivia.isEmpty || !token.leadingTrivia.isEmpty,
               ![.leftParen, .leftSquare].contains(previous.tokenKind),
               ![.rightParen, .rightSquare, .comma].contains(token.tokenKind) {
                text += " "
            }
            text += token.text
            previous = token
        }
        // A multi-line string literal's line breaks are in its text, not its trivia.
        return text.split(omittingEmptySubsequences: false) { $0.isNewline }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }
}

#endif
