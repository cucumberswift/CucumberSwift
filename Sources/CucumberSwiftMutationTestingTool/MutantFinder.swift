//
//  MutantFinder.swift
//  CucumberSwiftMutationTestingTool
//

#if Macros
import CucumberSwiftMutation
import Foundation
import SwiftParser
import SwiftSyntax

/// The replacements that each rule makes.
enum MutationRules {
    static let relational: [String: [String]] = [
        ">": [">=", "<="], ">=": [">", "<"], "<": ["<=", ">="], "<=": ["<", ">"], "==": ["!="], "!=": ["=="]
    ]
    static let logical: [String: [String]] = ["&&": ["||"], "||": ["&&"]]
}

/// Finds the mutants in one Swift file: a comparison operator changed, `&&` and `||` swapped, a `true` or
/// `false` flipped. It reads the code as swift-syntax parses it, so an operator inside a string or a comment
/// is not a mutant.
final class MutantFinder: SyntaxVisitor {
    private let file: String
    private let converter: SourceLocationConverter
    private(set) var found = [Mutant]()

    static func mutants(in source: String, file: String) -> [Mutant] {
        let tree = Parser.parse(source: source)
        let finder = MutantFinder(file: file, tree: tree)
        finder.walk(tree)
        return finder.found
    }

    private init(file: String, tree: SourceFileSyntax) {
        self.file = file
        converter = SourceLocationConverter(fileName: file, tree: tree)
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let text = node.operator.text
        for replacement in MutationRules.relational[text] ?? [] {
            add(node.operator, replacement: replacement, mutator: "RelationalOperator")
        }
        for replacement in MutationRules.logical[text] ?? [] {
            add(node.operator, replacement: replacement, mutator: "LogicalOperator")
        }
        return .visitChildren
    }

    override func visit(_ node: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        let flipped = node.literal.text == "true" ? "false" : "true"
        add(node.literal, replacement: flipped, mutator: "BooleanLiteral")
        return .visitChildren
    }

    private func add(_ token: TokenSyntax, replacement: String, mutator: String) {
        let start = token.positionAfterSkippingLeadingTrivia
        let length = token.text.utf8.count
        let end = AbsolutePosition(utf8Offset: start.utf8Offset + length)
        let first = converter.location(for: start)
        let last = converter.location(for: end)
        found.append(Mutant(id: found.count + 1, file: file, line: first.line, column: first.column,
                            endLine: last.line, endColumn: last.column, offset: start.utf8Offset, length: length,
                            original: token.text, replacement: replacement, mutator: mutator))
    }
}

struct SyntaxDiscoverer: MutantDiscovering {
    func mutants(inFiles files: [URL], relativeTo root: URL) throws -> [Mutant] {
        let prefix = root.resolvingSymlinksInPath().path + "/"
        return try files.flatMap { url -> [Mutant] in
            let source = try String(contentsOf: url, encoding: .utf8)
            let path = url.resolvingSymlinksInPath().path
            let relative = path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : url.lastPathComponent
            return MutantFinder.mutants(in: source, file: relative)
        }
    }
}
#endif
