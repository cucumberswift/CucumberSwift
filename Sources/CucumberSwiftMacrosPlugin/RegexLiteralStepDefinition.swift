//
//  RegexLiteralStepDefinition.swift
//  CucumberSwiftMacrosPlugin
//

#if Macros
import SwiftSyntax
import SwiftSyntaxBuilder

/// A step definition macro with a regex literal, such as `#Given(#/^I have (\d+) cukes$/#) { (count: Substring) in … }`.
extension StepDefinition {
    /// Whether the closure's own body may throw, which makes Swift infer that it throws, without the keyword.
    /// A `try` inside a `do` that catches everything counts too, which only types the closure as throwing.
    private static func mayThrow(_ closure: ClosureExprSyntax) -> Bool {
        closure.signature?.effectSpecifiers?.throwsClause != nil || BodyFinder.contains(in: closure) { node in
            node.is(ThrowStmtSyntax.self) || node.as(TryExprSyntax.self).map { $0.questionOrExclamationMark == nil } == true
        }
    }

    /// Whether a type is `Substring` or an optional `Substring`, in any of the ways it can be written.
    static func isSubstring(_ type: TypeSyntax) -> Bool {
        var text = Substring(type.trimmedDescription.filter { !$0.isWhitespace })
        while true {
            if text.hasSuffix("?") {
                text = text.dropLast()
            } else if let prefix = ["Optional<", "Swift.Optional<"].first(where: { text.hasPrefix($0) }), text.hasSuffix(">") {
                text = text.dropFirst(prefix.count).dropLast()
            } else {
                return text == "Substring" || text == "Swift.Substring"
            }
        }
    }

    /// The step definition with a regex literal, which reads the arguments from the match's `output`. The
    /// compiler checks them against the regex's `Output`: one per capture, of the capture's type.
    func expansion(keyword: String, regex: RegexLiteralPattern) -> ExprSyntax {
        let used = Set(parameters.map(\.name) + [step?.name].compactMap { $0 })
        let checksNoCaptures = parameters.isEmpty && !regex.isCertain
        let match = parameters.isEmpty && !checksNoCaptures ? "_" : Self.unique("match", avoiding: used)
        let stepName = step?.name ?? "_"

        var bindings = [String]()
        if checksNoCaptures {
            // A regex without captures has the output Substring, so this fails to compile if it has any.
            bindings.append("let _: Substring = \(match).output")
        } else if !parameters.isEmpty {
            // The whole output, so that a missing argument fails to compile as well as a wrong type.
            let names = ["_"] + parameters.map(\.name)
            let types = ["_"] + parameters.map { $0.type?.trimmedDescription ?? "_" }
            let annotation = parameters.contains { $0.type != nil } ? ": (\(types.joined(separator: ", ")))" : ""
            bindings.append("let (\(names.joined(separator: ", ")))\(annotation) = \(match).output")
        }

        let signature = closure.signature
        let attributes = signature?.attributes.map { "\($0.trimmedDescription) " }.joined() ?? ""
        let captureList = signature?.capture.map { "\($0.trimmedDescription) " } ?? ""
        let effects = signature?.effectSpecifiers?.trimmedDescription ?? ""
        let arguments = effects.isEmpty ? "\(match), \(stepName)" : "(\(match), \(stepName)) \(effects)"
        let body = (bindings.map { "    \($0)" } + [Self.reindented(closure.statements)]).filter { !$0.isEmpty }
        let opening = "{ \(attributes)\(captureList)\(arguments) in"
        guard Self.hasCaptureList(closure) else {
            return """
            \(raw: keyword)(\(literal)) \(raw: opening)
            \(raw: body.joined(separator: "\n"))
            }
            """
        }
        return typedExpansion(keyword: keyword, opening: opening, body: body)
    }

    /// The expansion of a closure with a capture list, its own or a nested closure's.
    private func typedExpansion(keyword: String, opening: String, body: [String]) -> ExprSyntax {
        let signature = closure.signature
        // As for a string pattern, the closure is typed as a constant first (see `expansion(keyword:)`). Its type
        // names the regex's output, which only the compiler knows, so a generic function gives it the type.
        let isAsync = signature?.effectSpecifiers?.asyncSpecifier != nil || Self.awaits(closure)
        let isMainActor = signature?.attributes.contains { $0.trimmedDescription == "@MainActor" } == true
        let isolation = isAsync || isMainActor ? "@MainActor " : ""
        // The sync step definition with a regex literal doesn't throw: a closure that throws takes the async one.
        var effectsOfType = ""
        if isAsync {
            effectsOfType = "async throws "
        } else if Self.mayThrow(closure) {
            effectsOfType = "throws "
        }
        let type = "\(isolation)(Regex<Output>.Match, Step) \(effectsOfType)-> Void"
        var tokens = Set(closure.tokens(viewMode: .sourceAccurate).map(\.text))
        let function = Self.unique("typedCallback", avoiding: tokens)
        tokens.insert(function)
        let regexConstant = Self.unique("regex", avoiding: tokens)
        tokens.insert(regexConstant)
        let constant = Self.unique("callback", avoiding: tokens)
        let indented = body.joined(separator: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.isEmpty ? "" : "    \($0)" }
        return """
        { () -> \(raw: keyword) in
            func \(raw: function)<Output>(_: Regex<Output>, _ callback: @escaping \(raw: type)) -> \(raw: type) {
                callback
            }
            let \(raw: regexConstant) = \(literal)
            let \(raw: constant) = \(raw: function)(\(raw: regexConstant)) \(raw: opening)
        \(raw: indented.joined(separator: "\n"))
            }
            return \(raw: keyword)(\(raw: regexConstant), callback: \(raw: constant))
        }()
        """
    }
}
#endif
