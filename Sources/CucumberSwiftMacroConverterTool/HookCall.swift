//
//  HookCall.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

/// One hook call, such as `BeforeScenario(priority: 1) { scenario in … }`, converted to its macro,
/// `#BeforeScenario(priority: 1) { scenario in … }`. The macro takes the same arguments and closure, and
/// expands to the call as written, so a hook converts unless it passes a function or an argument the macros
/// don't take.
struct HookCall {
    /// The hooks, which both runners have a macro for.
    static let names: Set<String> = ["BeforeFeature", "AfterFeature", "BeforeScenario", "AfterScenario", "BeforeStep", "AfterStep"]

    let call: FunctionCallExprSyntax
    let runner: Runner

    /// The hook, when the call looks like one: a hook's name, and a closure or function to call.
    static func hook(of call: FunctionCallExprSyntax) -> String? {
        guard let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text, names.contains(name),
              call.trailingClosure != nil || call.arguments.contains(where: { $0.label?.text == "closure" }) else { return nil }
        return name
    }

    func macro() throws -> MacroExpansionExprSyntax {
        guard runner.found != nil else { throw Unconvertible(reason: runner.problem ?? "") }
        let labels: Set<String> = ["priority", "file", "line", "closure"]
        if let other = call.arguments.first(where: { !labels.contains($0.label?.text ?? "") }) {
            let label = other.label.map { "`\($0.text):`" } ?? "an argument without a label"
            throw Unconvertible(reason: "it passes \(label), which the macros don't take")
        }
        let body = call.trailingClosure.map { ExprSyntax($0) } ?? call.arguments.first { $0.label?.text == "closure" }?.expression
        guard body?.is(ClosureExprSyntax.self) == true, call.additionalTrailingClosures.isEmpty else {
            throw Unconvertible(reason: "it passes a function, and the macros take a closure")
        }
        let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName ?? .identifier("")
        return MacroExpansionExprSyntax(
            leadingTrivia: name.leadingTrivia,
            pound: .poundToken(),
            macroName: name.with(\.leadingTrivia, []),
            leftParen: call.leftParen,
            arguments: call.arguments,
            rightParen: call.rightParen,
            trailingClosure: call.trailingClosure,
            additionalTrailingClosures: call.additionalTrailingClosures)
    }
}
#endif
