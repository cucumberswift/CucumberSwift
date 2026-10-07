//
//  Rewriter.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

final class Rewriter: SyntaxRewriter {
    private let runner: Runner
    private let converter: SourceLocationConverter
    private(set) var converted = [StepDefinitionConverter.Entry]()
    private(set) var leftUnchanged = [StepDefinitionConverter.Entry]()

    /// The keyword, when the call looks like a step definition: a keyword, a first argument without a
    /// label, and a closure or function to call. `Given(I: …)` in the DSL is not one.
    private static func keyword(of call: FunctionCallExprSyntax) -> String? {
        guard let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
              StepDefinitionConverter.keywords.contains(name) || StepDefinitionConverter.localizedNames.contains(name),
              let first = call.arguments.first, first.label == nil else { return nil }
        let labels = call.arguments.dropFirst().compactMap { $0.label?.text }
        guard call.trailingClosure != nil || labels.contains("callback") || labels.contains("class") else { return nil }
        return name
    }

    init(runner: Runner, converter: SourceLocationConverter) {
        self.runner = runner
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // The line in the source as given; converting a step definition inside this one moves nothing before it.
        let line = node.startLocation(converter: converter).line
        let visited = super.visit(node)
        guard let call = visited.as(FunctionCallExprSyntax.self),
              let keyword = Self.keyword(of: call) else { return visited }
        let description = "\(keyword)(\(call.arguments.first?.expression.trimmedDescription ?? ""))"
        do {
            let macro = try StepDefinitionCall(call, keyword: keyword, runner: runner).macro()
            converted.append(.init(line: line, stepDefinition: description, reason: nil))
            return ExprSyntax(macro)
        } catch let problem as Unconvertible {
            leftUnchanged.append(.init(line: line, stepDefinition: description, reason: problem.reason))
            return visited
        } catch {
            return visited
        }
    }
}
#endif
