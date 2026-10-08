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

    /// Whether a function, variable, type or parameter called `name` is declared where the call is: in a block
    /// that contains it, in a type that contains it, or as a parameter of a function or closure that contains
    /// it, in this file.
    private static func isShadowed(_ name: String, around node: some SyntaxProtocol) -> Bool {
        var ancestor = Syntax(node).parent
        while let current = ancestor {
            if let items = current.as(CodeBlockItemListSyntax.self), items.contains(where: { declares(name, $0.item) }) {
                return true
            }
            if let members = current.as(MemberBlockItemListSyntax.self), members.contains(where: { declares(name, Syntax($0.decl)) }) {
                return true
            }
            if hasParameter(named: name, current) { return true }
            ancestor = current.parent
        }
        return false
    }

    /// Whether the function, initializer or closure takes a parameter called `name`.
    private static func hasParameter(named name: String, _ node: Syntax) -> Bool {
        func contains(_ clause: FunctionParameterClauseSyntax) -> Bool {
            clause.parameters.contains { ($0.secondName ?? $0.firstName).text == name }
        }
        if let function = node.as(FunctionDeclSyntax.self) { return contains(function.signature.parameterClause) }
        if let initializer = node.as(InitializerDeclSyntax.self) { return contains(initializer.signature.parameterClause) }
        guard let closure = node.as(ClosureExprSyntax.self) else { return false }
        switch closure.signature?.parameterClause {
            case .simpleInput(let list): return list.contains { $0.name.text == name }
            case .parameterClause(let clause): return clause.parameters.contains { ($0.secondName ?? $0.firstName).text == name }
            case nil: return false
        }
    }

    private static func declares(_ name: String, _ item: some SyntaxProtocol) -> Bool {
        let syntax = Syntax(item)
        if let function = syntax.as(FunctionDeclSyntax.self) { return function.name.text == name }
        if let variable = syntax.as(VariableDeclSyntax.self) {
            return variable.bindings.contains { $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name }
        }
        if let type = syntax.as(StructDeclSyntax.self) { return type.name.text == name }
        if let type = syntax.as(ClassDeclSyntax.self) { return type.name.text == name }
        if let type = syntax.as(EnumDeclSyntax.self) { return type.name.text == name }
        if let alias = syntax.as(TypeAliasDeclSyntax.self) { return alias.name.text == name }
        return false
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
        // The original node still has its parents, which the rewritten one doesn't.
        if Self.isShadowed(keyword, around: node) {
            let reason = "a `\(keyword)` declared in this file is in scope, so the call may not be a step definition"
            leftUnchanged.append(.init(line: line, stepDefinition: description, reason: reason))
            return visited
        }
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
