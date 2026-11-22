//
//  DSLContainerMacro.swift
//  CucumberSwiftMacrosPlugin
//

#if Macros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// The parts of a feature written in the Swift DSL, as macros, so that a feature can be written in the macro
/// style throughout: `#Feature("Checkout") { #Scenario("Buy cukes") { #Given(I: addCukes(2)) } }`. Each expands to
/// the call it stands for, with the same arguments, and the line and column of its opening parenthesis, which the
/// call would otherwise take from its default arguments, written in when the tests compile.
enum DSLContainer {
    /// The labels of the arguments that come after the position: the closures that hold the container's contents.
    static let contentLabels: Set<String> = ["steps", "examples"]

    /// Where the macro's opening parenthesis is, which is where the function form's `#line` and `#column` point.
    /// The test context of swift-syntax 600 can't locate a token inside the macro, only the macro itself (601
    /// fixed that), so there the column is counted on from the macro to the parenthesis.
    static func location(of node: some FreestandingMacroExpansionSyntax,
                         in context: some MacroExpansionContext) -> AbstractSourceLocation? {
        if let marked = PositionMarker.location(in: node) { return marked }
        guard let paren = node.leftParen else {
            return context.location(of: node, at: .afterLeadingTrivia, filePathMode: .filePath)
        }
        if let location = context.location(of: paren, at: .afterLeadingTrivia, filePathMode: .filePath) {
            return location
        }
        let start = node.positionAfterSkippingLeadingTrivia.utf8Offset
        let distance = paren.positionAfterSkippingLeadingTrivia.utf8Offset - start
        let before = Array(node.syntaxTextBytes.dropFirst(node.leadingTriviaLength.utf8Length).prefix(distance))
        guard !before.contains(UInt8(ascii: "\n")), !before.contains(UInt8(ascii: "\r")),
              let location = context.location(of: node, at: .afterLeadingTrivia, filePathMode: .filePath),
              let column = location.column.as(IntegerLiteralExprSyntax.self).flatMap({ Int($0.literal.text) }) else {
            return nil
        }
        return AbstractSourceLocation(file: location.file, line: location.line, column: "\(literal: column + distance)")
    }

    /// The call with `position` added before the container's contents: before its first closure argument other
    /// than the title, which a `ScenarioOutline` can give as a closure, and before any trailing closures.
    static func expansion(of node: some FreestandingMacroExpansionSyntax,
                          in context: some MacroExpansionContext,
                          withFile: Bool,
                          withPosition: Bool = true) -> ExprSyntax {
        DSLPlacement.reportStepDefinitions(in: node, context: context)
        // A macro inside the container is expanded from the container's expansion, where the compiler counts its lines
        // from the start of that expansion, so the container writes each one's position, in the Swift file, onto it first.
        let marking = !PositionMarker.isMarked(node)
        func marked(_ expression: ExprSyntax) -> ExprSyntax {
            marking ? PositionMarker.marked(expression, in: context) : expression
        }
        func marked(_ closure: ClosureExprSyntax) -> ClosureExprSyntax {
            ClosureExprSyntax(marked(ExprSyntax(closure))) ?? closure
        }
        var arguments = Array(node.arguments).map { $0.with(\.expression, marked($0.expression)) }
        let trailingClosure = node.trailingClosure.map(marked)
        let additionalTrailingClosures = MultipleTrailingClosureElementListSyntax(
            node.additionalTrailingClosures.map { $0.with(\.closure, marked($0.closure)) })
        if withPosition {
            let location = location(of: node, in: context)
            var position: [LabeledExprSyntax] = [
                LabeledExprSyntax(label: "line", expression: location?.line ?? "#line"),
                LabeledExprSyntax(label: "column", expression: location?.column ?? "#column")
            ]
            if withFile {
                position.append(LabeledExprSyntax(label: "file", expression: location?.file ?? "#filePath"))
            }
            let contentIndex = arguments.indices.first { index in
                let argument = arguments[index]
                if let label = argument.label?.text { return contentLabels.contains(label) }
                return index > 0 && argument.expression.is(ClosureExprSyntax.self)
            } ?? arguments.endIndex
            arguments.insert(contentsOf: position, at: contentIndex)
        }
        // Commas between the arguments, and none after the last.
        let list = LabeledExprListSyntax(arguments.enumerated().map { index, argument in
            argument
                .with(\.trailingComma, index < arguments.count - 1 ? .commaToken(trailingTrivia: .space) : nil)
        })
        let call = FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: node.macroName.with(\.leadingTrivia, []).with(\.trailingTrivia, [])),
            leftParen: .leftParenToken(),
            arguments: list,
            rightParen: .rightParenToken(),
            trailingClosure: trailingClosure,
            additionalTrailingClosures: additionalTrailingClosures)
        return ExprSyntax(call)
    }
}

/// `#Feature`: the feature, with its position and the Swift file it is written in.
public struct DSLFeatureMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in context: some MacroExpansionContext) throws -> ExprSyntax {
        DSLContainer.expansion(of: node, in: context, withFile: true)
    }
}

/// `#Scenario`, `#ScenarioOutline` and `#Rule`: the container, with its position.
public struct DSLScenarioMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in context: some MacroExpansionContext) throws -> ExprSyntax {
        DSLContainer.expansion(of: node, in: context, withFile: false)
    }
}

/// `#Background` and `#Description`, which have no position: the call as written.
public struct DSLPartMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in context: some MacroExpansionContext) throws -> ExprSyntax {
        DSLContainer.expansion(of: node, in: context, withFile: false, withPosition: false)
    }
}

/// The position, in the Swift file, of a DSL macro inside another one's contents, written onto the macro as a comment
/// before it: `/*cucumberswift-position:16:13:/path/File.swift*/ #Scenario(…)`. The container macro that holds it
/// writes the comment, because only its own node is in the Swift file: its contents' macros expand from its expansion.
enum PositionMarker {
    static let prefix = "/*cucumberswift-position:"
    /// The macros that have no position to write.
    static let unpositioned: Set<String> = ["Background", "Description"]

    /// The marker of `node`, if the macro around it wrote one.
    static func location(in node: some FreestandingMacroExpansionSyntax) -> AbstractSourceLocation? {
        for piece in node.pound.leadingTrivia.reversed() {
            guard case .blockComment(let text) = piece, text.hasPrefix(prefix), text.hasSuffix("*/") else { continue }
            let parts = text.dropFirst(prefix.count).dropLast(2).split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
            guard parts.count == 3, let line = Int(parts[0]), let column = Int(parts[1]) else { return nil }
            return AbstractSourceLocation(file: "\(literal: String(parts[2]))", line: "\(literal: line)", column: "\(literal: column)")
        }
        return nil
    }

    static func isMarked(_ node: some FreestandingMacroExpansionSyntax) -> Bool { location(in: node) != nil }

    /// `syntax` with a marker on each macro in it that has none, at its position in the Swift file.
    static func marked(_ syntax: ExprSyntax, in context: some MacroExpansionContext) -> ExprSyntax {
        MarkingRewriter(context: context).rewrite(Syntax(syntax)).cast(ExprSyntax.self)
    }
}

private final class MarkingRewriter: SyntaxRewriter {
    let context: any MacroExpansionContext

    init(context: any MacroExpansionContext) {
        self.context = context
        super.init()
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        // A part with no position, and a step definition, which is reported as an error, take no marker.
        let name = node.macroName.text
        guard !PositionMarker.unpositioned.contains(name),
              !(DSLPlacement.stepNames.contains(name) && DSLPlacement.isStepDefinition(node.arguments)),
              !PositionMarker.isMarked(node), var expansion = visited.as(MacroExpansionExprSyntax.self),
              let location = DSLContainer.location(of: node, in: context),
              let line = location.line.as(IntegerLiteralExprSyntax.self)?.literal.text,
              let column = location.column.as(IntegerLiteralExprSyntax.self)?.literal.text,
              let file = location.file.as(StringLiteralExprSyntax.self)?.representedLiteralValue,
              !file.contains("*/") else { return visited }
        let marker = Trivia(pieces: [.blockComment("\(PositionMarker.prefix)\(line):\(column):\(file)*/"), .spaces(1)])
        expansion.pound = expansion.pound.with(\.leadingTrivia, expansion.pound.leadingTrivia + marker)
        return ExprSyntax(expansion)
    }
}
#endif
