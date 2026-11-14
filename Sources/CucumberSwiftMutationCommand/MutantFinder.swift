//
//  MutantFinder.swift
//  CucumberSwiftMutationCommand
//

#if Macros && (os(macOS) || os(Linux))
import CucumberSwiftMutation
import Foundation
import SwiftOperators
import SwiftParser
import SwiftSyntax

/// The replacements that each rule makes.
enum MutationRules {
    static let relational: [String: [String]] = [
        ">": [">=", "<="], ">=": [">", "<"], "<": ["<=", ">="], "<=": ["<", ">"], "==": ["!="], "!=": ["=="]
    ]
    static let logical: [String: [String]] = ["&&": ["||"], "||": ["&&"]]
    static let arithmetic: [String: [String]] = ["+": ["-"], "-": ["+"], "*": ["/"], "/": ["*"]]
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

/// The lines that a `// cucumberswift:mutation-ignore` comment marks, and the text after the marker. A comment at the
/// end of a line marks that line, and a comment on a line of its own marks the next line of code.
final class IgnoreMarkers: SyntaxVisitor {
    static let marker = "cucumberswift:mutation-ignore"

    private let converter: SourceLocationConverter
    private(set) var lines = [Int: String]()

    init(tree: SourceFileSyntax, converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
        walk(tree)
    }

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        for piece in Array(token.leadingTrivia) + Array(token.trailingTrivia) {
            guard case .lineComment(let text) = piece, let range = text.range(of: Self.marker) else { continue }
            let reason = text[range.upperBound...].trimmingCharacters(in: CharacterSet(charactersIn: " :-"))
            lines[converter.location(for: token.positionAfterSkippingLeadingTrivia).line] = reason
        }
        return .visitChildren
    }
}

/// Finds the mutants in one Swift file. It reads the code as swift-syntax parses it, with the standard operators'
/// precedence, so an operator inside a string or a comment is never a mutant, and an operator's operands are known.
///
/// The rules are deterministic: the same file always gives the same mutants, in the same order.
///
/// - `RelationalOperator`: `>` becomes `>=` and `<=`, `>=` becomes `>` and `<`, and so on; `==` and `!=` swap.
/// - `LogicalOperator`: `&&` and `||` swap.
/// - `ArithmeticOperator`: `+` and `-` swap, and `*` and `/` swap, unless an operand is a string literal.
/// - `BooleanLiteral`: `true` and `false` swap.
/// - `LogicalNot`: the `!` of `!condition` is removed.
/// - `SwapTernary`: `c ? a : b` becomes `c ? b : a`.
/// - `RemoveCall`: a call whose result isn't used, such as `save(user)`, is removed, except logging and assertions
///   (``keptCalls``), and except the value of a closure or function that returns it without `return`.
final class MutantFinder: SyntaxVisitor {
    /// Calls that `RemoveCall` leaves alone: removing them changes only what is logged, which no scenario checks, or turns
    /// a crash into a bad result. The logging names cover `Logger` and `os_log` style calls such as `logger.info(…)`.
    static let keptCalls: Set<String> = [
        "print", "debugPrint", "NSLog", "os_log", "log", "trace", "debug", "info", "notice", "warning", "error", "critical", "fault",
        "assert", "assertionFailure", "precondition", "preconditionFailure", "fatalError"
    ]

    private let file: String
    private let bytes: [UInt8]
    private let converter: SourceLocationConverter
    private let ignored: [Int: String]
    private(set) var found = [Mutant]()

    static func mutants(in source: String, file: String) -> [Mutant] {
        let tree = Parser.parse(source: source)
        let finder = MutantFinder(file: file, source: source, tree: tree)
        // Folded, an expression is a tree of operations with their operands, in the positions of the source.
        let folded = OperatorTable.standardOperators.foldAll(tree) { _ in
            // An operator the table doesn't know stays unfolded, and its operands are visited all the same.
        }
        finder.walk(folded)
        // A folded expression is visited outermost operation first: list the mutants in the order of the source.
        let ordered = finder.found.enumerated().sorted { ($0.element.offset, $0.offset) < ($1.element.offset, $1.offset) }
        return ordered.enumerated().map { $1.element.numbered($0 + 1) }
    }

    private init(file: String, source: String, tree: SourceFileSyntax) {
        self.file = file
        bytes = Array(source.utf8)
        converter = SourceLocationConverter(fileName: file, tree: tree)
        ignored = IgnoreMarkers(tree: tree, converter: converter).lines
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard let token = node.operator.as(BinaryOperatorExprSyntax.self)?.operator else { return .visitChildren }
        let text = token.text
        for replacement in MutationRules.relational[text] ?? [] {
            add(token, replacement: replacement, mutator: "RelationalOperator")
        }
        for replacement in MutationRules.logical[text] ?? [] {
            add(token, replacement: replacement, mutator: "LogicalOperator")
        }
        let isText = node.leftOperand.is(StringLiteralExprSyntax.self) || node.rightOperand.is(StringLiteralExprSyntax.self)
        for replacement in MutationRules.arithmetic[text] ?? [] where !isText {
            add(token, replacement: replacement, mutator: "ArithmeticOperator")
        }
        return .visitChildren
    }

    override func visit(_ node: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        let flipped = node.literal.text == "true" ? "false" : "true"
        add(node.literal, replacement: flipped, mutator: "BooleanLiteral")
        return .visitChildren
    }

    override func visit(_ node: PrefixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        if node.operator.text == "!" { add(node.operator, replacement: "", mutator: "LogicalNot") }
        return .visitChildren
    }

    /// The mutant replaces the whole expression, condition included, so that its place is the code that runs whenever the
    /// expression does. At the `then` branch, it would count as code that only the scenarios entering that branch run,
    /// although the swap changes what both branches return.
    override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
        let conditionStart = node.condition.positionAfterSkippingLeadingTrivia
        let thenStart = node.thenExpression.positionAfterSkippingLeadingTrivia
        let thenEnd = node.thenExpression.endPositionBeforeTrailingTrivia
        let elseStart = node.elseExpression.positionAfterSkippingLeadingTrivia
        let elseEnd = node.elseExpression.endPositionBeforeTrailingTrivia
        let swapped = text(conditionStart, thenStart) + text(elseStart, elseEnd) + text(thenEnd, elseStart) + text(thenStart, thenEnd)
        add(from: conditionStart, to: elseEnd, replacement: swapped, mutator: "SwapTernary")
        return .visitChildren
    }

    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        if isRemovableCall(node) {
            add(from: node.positionAfterSkippingLeadingTrivia, to: node.endPositionBeforeTrailingTrivia, replacement: "", mutator: "RemoveCall")
        }
        return .visitChildren
    }

    /// Whether `item` is a call on its own, whose result isn't used, that isn't the value a closure or function returns
    /// without `return`.
    private func isRemovableCall(_ item: CodeBlockItemSyntax) -> Bool {
        guard case .expr(var expression) = item.item else { return false }
        while true {
            if let tried = expression.as(TryExprSyntax.self) { expression = tried.expression; continue }
            if let awaited = expression.as(AwaitExprSyntax.self) { expression = awaited.expression; continue }
            break
        }
        guard let call = expression.as(FunctionCallExprSyntax.self) else { return false }
        let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
            ?? call.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        if let name, Self.keptCalls.contains(name) { return false }
        guard let list = item.parent?.as(CodeBlockItemListSyntax.self), list.count == 1 else { return true }
        // A single expression is the value of a closure, or of a function that returns one.
        if list.parent?.is(ClosureExprSyntax.self) == true { return false }
        if let function = list.parent?.parent?.as(FunctionDeclSyntax.self), function.signature.returnClause != nil { return false }
        return true
    }

    private func text(_ start: AbsolutePosition, _ end: AbsolutePosition) -> String {
        let range = max(0, start.utf8Offset)..<min(bytes.count, end.utf8Offset)
        return String(bytes: bytes[range], encoding: .utf8) ?? ""
    }

    private func add(_ token: TokenSyntax, replacement: String, mutator: String) {
        let start = token.positionAfterSkippingLeadingTrivia
        add(from: start, to: AbsolutePosition(utf8Offset: start.utf8Offset + token.text.utf8.count), replacement: replacement, mutator: mutator)
    }

    private func add(from start: AbsolutePosition, to end: AbsolutePosition, replacement: String, mutator: String) {
        let first = converter.location(for: start)
        let last = converter.location(for: end)
        var mutant = Mutant(
            id: found.count + 1,
            file: file,
            line: first.line,
            column: first.column,
            endLine: last.line,
            endColumn: last.column,
            offset: start.utf8Offset,
            length: end.utf8Offset - start.utf8Offset,
            original: text(start, end),
            replacement: replacement,
            mutator: mutator
        )
        mutant.ignoredReason = ignored[first.line]
        found.append(mutant)
    }
}

#endif
