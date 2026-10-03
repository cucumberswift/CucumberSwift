//
//  StepNodeContent.swift
//  CucumberSwift
//

import Foundation

/// What a step in a feature file holds, read from its tokens: its keyword, its text, and its doc
/// string or data table. ``Step`` is built from it, and so are the steps that build tools read.
struct StepNodeContent {
    private(set) var keyword: Step.Keyword = []
    private(set) var match = ""
    private(set) var docString: DocString?
    /// The data table's rows, empty when the step has no table. A cell that is still an outline's
    /// `<placeholder>` keeps its angle brackets.
    let tableRows: [[String]]
    /// Where the step's keyword is.
    let location: Lexer.Position
    /// The step's tokens without its keyword.
    let tokens: [Lexer.Token]

    init(_ node: AST.StepNode) {
        location = node.tokens.first { $0.isKeyword() }?.position ?? .start
        tokens = node.tokens.filter { !$0.isKeyword() }
        for token in node.tokens {
            if case Lexer.Token.keyword(_, let kw) = token {
                keyword = kw
            } else if case Lexer.Token.match(_, let m) = token {
                match += m
            } else if case Lexer.Token.tableHeader(_, let h) = token {
                match += h
            } else if case Lexer.Token.docString(_, let s) = token {
                docString = s
            }
        }
        tableRows = node.tokens
            .filter { $0.isTableCell() || $0.isNewline() }
            .groupedByLine()
            .map { line -> [String] in
                line.filter { $0.isTableCell() }
                    .map { token -> String in
                        if case Lexer.Token.tableCell(_, let cellToken) = token {
                            if case Lexer.Token.tableHeader = cellToken {
                                return "<\(cellToken.valueDescription)>"
                            }
                            return cellToken.valueDescription
                        }
                        return ""
                    }
            }
        match = match.trimmingCharacters(in: .whitespaces)
    }
}
