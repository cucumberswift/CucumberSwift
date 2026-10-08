//
//  StepDefinitionCall+Rewriting.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftParser
import SwiftSyntax

// Writing the macro: the closure without its reads, and the call around it.
extension StepDefinitionCall {
    /// The spaces and tabs after the last line break.
    static func indentation(of trivia: Trivia) -> [TriviaPiece] {
        Array(trivia.pieces.reversed().prefix { !$0.isNewline }.reversed().filter { $0.isSpaceOrTab })
    }

    func rewritten(_ closure: ClosureExprSyntax, parameters: [String], droppingReads count: Int) throws -> ClosureExprSyntax {
        var closure = closure
        try replaceParameters(of: &closure, with: parameters)
        guard count > 0 else { return closure }

        let removed = closure.statements.prefix(count)
        let comments = removed.flatMap { item in
            item.tokens(viewMode: .sourceAccurate).flatMap { ($0.leadingTrivia + $0.trailingTrivia).pieces.filter(\.isComment) }
        }
        let indentation = Self.indentation(of: removed.first?.leadingTrivia ?? [])
        var kept = Array(closure.statements.dropFirst(count))
        // Each comment on a line of its own, where the reads were.
        let carried = comments.flatMap { [TriviaPiece.newlines(1)] + indentation + [$0] }
        if var first = kept.first {
            var trivia = first.leadingTrivia.pieces
            if carried.isEmpty, trivia.first?.isNewline == true {
                // The reads are gone, and with them the blank line that set them apart from the code.
                trivia = [.newlines(1)] + indentation + trivia.drop { $0.isWhitespace }
            }
            first.leadingTrivia = Trivia(pieces: carried + trivia)
            kept[0] = first
        } else {
            closure.rightBrace.leadingTrivia = Trivia(pieces: carried) + closure.rightBrace.leadingTrivia
        }
        closure.statements = CodeBlockItemListSyntax(kept)
        return closure
    }

    /// Gives the closure the macro's arguments, or none when it has none to take.
    private func replaceParameters(of closure: inout ClosureExprSyntax, with parameters: [String]) throws {
        guard let signature = closure.signature else { return }
        let old = signature.parameterClause
        let clause: ClosureParameterClauseSyntax
        if parameters.isEmpty {
            let bare = signature.with(\.parameterClause, nil)
            if bare.effectSpecifiers == nil, bare.returnClause == nil {
                guard bare.attributes.isEmpty, bare.capture == nil else {
                    closure.signature = bare
                    return
                }
                closure.signature = nil
                // `{ _, _ in` on its own line becomes `{`, without a space before the line break.
                if closure.statements.first?.leadingTrivia.first?.isNewline ?? true {
                    closure.leftBrace = closure.leftBrace.with(\.trailingTrivia, [])
                }
                return
            }
            // `async`, `throws` and `->` need a parameter clause to follow: `{ () async in`.
            clause = ClosureParameterClauseSyntax(parameters: [])
        } else {
            // Parsed as part of a closure, the only place the parser accepts closure parameters.
            let parsed = Parser.parse(source: "{ (\(parameters.joined(separator: ", "))) in }")
            guard !parsed.hasError,
                  let parsedClause = parsed.statements.first?.item.as(ClosureExprSyntax.self)?.signature?.parameterClause?
                    .as(ClosureParameterClauseSyntax.self) else {
                throw Unconvertible(reason: "its closure's new parameters, \(parameters.joined(separator: ", ")), don't parse")
            }
            clause = parsedClause
        }
        closure.signature = signature.with(\.parameterClause, .parameterClause(clause
            .with(\.leadingTrivia, old?.leadingTrivia ?? [])
            .with(\.trailingTrivia, old?.trailingTrivia ?? .space)))
    }

    func makeMacro(closure: ClosureExprSyntax, pattern: StringLiteralExprSyntax?) -> MacroExpansionExprSyntax {
        var arguments = Array(call.arguments)
        if let pattern { arguments[0] = arguments[0].with(\.expression, ExprSyntax(pattern)) }
        if call.trailingClosure == nil, arguments.count == 2 {
            // `Given("…", callback: { … })` becomes `#Given("…", { … })`, as the macros don't label it.
            let label = arguments[1].label
            let unlabelled = arguments[1].with(\.label, nil).with(\.colon, nil)
            arguments[1] = unlabelled.with(\.expression, ExprSyntax(closure).with(\.leadingTrivia, label?.leadingTrivia ?? []))
        }
        let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName ?? .identifier(keyword)
        return MacroExpansionExprSyntax(
            leadingTrivia: name.leadingTrivia,
            pound: .poundToken(),
            macroName: name.with(\.leadingTrivia, []),
            leftParen: call.leftParen,
            arguments: LabeledExprListSyntax(arguments),
            rightParen: call.rightParen,
            trailingClosure: call.trailingClosure == nil ? nil : closure,
            additionalTrailingClosures: call.additionalTrailingClosures)
    }
}
#endif
