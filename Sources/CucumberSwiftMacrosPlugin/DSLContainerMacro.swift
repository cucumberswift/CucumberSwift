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
        var arguments = Array(node.arguments)
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
            trailingClosure: node.trailingClosure,
            additionalTrailingClosures: node.additionalTrailingClosures)
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
#endif
