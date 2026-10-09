//
//  StepDefinitionCall+Reads.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

// What the closure reads from `match`, and whether it uses `match` for anything else.
extension StepDefinitionCall {
    /// `let name[: Type] = try match.first(\.parameter)` or `let name[: Type] = match[\.parameter, index: n]`.
    static func read(_ item: CodeBlockItemSyntax, match: String) -> Source? {
        guard let declaration = item.item.as(VariableDeclSyntax.self),
              declaration.bindingSpecifier.tokenKind == .keyword(.let),
              declaration.attributes.isEmpty, declaration.modifiers.isEmpty,
              declaration.bindings.count == 1, let binding = declaration.bindings.first,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let value = binding.initializer?.value else { return nil }
        let type = binding.typeAnnotation?.type
        if let attempt = value.as(TryExprSyntax.self), attempt.questionOrExclamationMark == nil,
           let call = attempt.expression.as(FunctionCallExprSyntax.self),
           let member = call.calledExpression.as(MemberAccessExprSyntax.self),
           member.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == match,
           member.declName.baseName.text == "first", call.trailingClosure == nil,
           call.arguments.count == 1, let argument = call.arguments.first, argument.label == nil,
           let parameter = keyPathParameter(argument.expression) {
            return Source(name: name, type: type, parameter: parameter, index: nil)
        }
        if let subscriptCall = value.as(SubscriptCallExprSyntax.self),
           subscriptCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == match,
           subscriptCall.arguments.count == 2,
           let first = subscriptCall.arguments.first, first.label == nil,
           let parameter = keyPathParameter(first.expression),
           let second = subscriptCall.arguments.last, second.label?.text == "index",
           let index = second.expression.as(IntegerLiteralExprSyntax.self).flatMap({ Int($0.literal.text) }) {
            return Source(name: name, type: type, parameter: parameter, index: index)
        }
        return nil
    }

    /// `parameter` in `\.parameter`.
    static func keyPathParameter(_ expression: ExprSyntax) -> String? {
        guard let keyPath = expression.as(KeyPathExprSyntax.self), keyPath.root == nil,
              keyPath.components.count == 1,
              let property = keyPath.components.first?.component.as(KeyPathPropertyComponentSyntax.self),
              property.genericArgumentClause == nil else { return nil }
        return property.declName.baseName.text
    }

    static func isMember(_ use: DeclReferenceExprSyntax, named name: String) -> Bool {
        use.parent?.as(MemberAccessExprSyntax.self)?.declName.baseName.text == name
    }

    static func isIntegerSubscript(_ use: DeclReferenceExprSyntax) -> Bool {
        guard let subscriptCall = use.parent?.as(SubscriptCallExprSyntax.self) else { return false }
        return subscriptCall.arguments.count == 1 && subscriptCall.arguments.first?.expression.is(IntegerLiteralExprSyntax.self) == true
    }

    static func references(_ name: String, in rest: some Sequence<CodeBlockItemSyntax>) -> Bool {
        rest.contains { !References(of: name).uses(in: Syntax($0)).isEmpty }
    }

    /// The statements at the top of the closure that read a parameter the way the expansion does.
    func reads(in closure: ClosureExprSyntax, match: Parameter, pattern: StepPattern) throws -> [Read] {
        guard match.name != "_" else { return [] }
        var countByParameter = [String: Int]()
        for capture in pattern.captures { countByParameter[capture.parameter, default: 0] += 1 }

        var reads = [Read]()
        for item in closure.statements {
            guard let source = Self.read(item, match: match.name) else { break }
            let (name, type, parameter, index) = (source.name, source.type, source.parameter, source.index)
            let count = countByParameter[parameter] ?? 0
            guard count > 0 else {
                throw Unconvertible(reason: "it reads {\(parameter)}, which its pattern doesn't have")
            }
            let occurrence: Int
            if let index {
                guard count > 1 else {
                    throw Unconvertible(reason: "it reads {\(parameter)} as \(match.name)[\\.\(parameter), index: \(index)], "
                        + "and the macro reads a parameter type the pattern has once as \(match.name).first(\\.\(parameter))")
                }
                guard index < count else {
                    throw Unconvertible(reason: "it reads {\(parameter)} at index \(index), and its pattern has \(count)")
                }
                occurrence = index
            } else {
                guard count == 1 else {
                    throw Unconvertible(reason: "it reads {\(parameter)} with first(\\.\(parameter)), and the macro reads a parameter type "
                        + "the pattern has more than once by position, as \(match.name)[\\.\(parameter), index: 0]")
                }
                occurrence = 0
            }
            let capture = pattern.captures.indices.filter { pattern.captures[$0].parameter == parameter }[occurrence]
            if let last = reads.last, capture <= last.capture {
                throw Unconvertible(reason: reads.contains { $0.capture == capture }
                    ? "it reads {\(parameter)} more than once"
                    : "it reads its parameters in a different order from its pattern")
            }
            reads.append(Read(name: name, type: type, capture: capture))
        }
        return reads
    }

    /// The type the macro's closure gives the parameter: the one the read declares, or the built-in one.
    func parameterType(of read: Read?, capture: StepPattern.Capture) throws -> String? {
        guard let declared = read?.type?.trimmedDescription else { return capture.type }
        if let expected = capture.type, declared != expected, declared != "Swift.\(expected)" {
            throw Unconvertible(reason: "it declares {\(capture.parameter)} as \(declared), and the macro gives it as \(expected)")
        }
        return declared
    }

    func checkTheRest(_ rest: some Sequence<CodeBlockItemSyntax>, match: Parameter, isRegexLiteral: Bool = false) throws {
        guard match.name != "_" else { return }
        let uses = rest.flatMap { References(of: match.name).uses(in: Syntax($0)) }
        guard let use = uses.first else { return }
        if uses.contains(where: { Self.isMember($0, named: "allParameters") }) {
            throw Unconvertible(reason: "it reads \(match.name).allParameters")
        }
        if uses.contains(where: Self.isIntegerSubscript) {
            throw Unconvertible(reason: "it uses the deprecated [String] closure")
        }
        if Self.isMember(use, named: "first") || use.parent?.is(SubscriptCallExprSyntax.self) == true {
            throw Unconvertible(reason: "it reads a parameter of \(match.name) after other code, or not with let, "
                + "and the macro reads every parameter before the closure's code")
        }
        if isRegexLiteral, use.parent?.is(MemberAccessExprSyntax.self) == true {
            throw Unconvertible(reason: "it reads \(match.name) after other code, or in another form than `let name = \(match.name).1`, "
                + "and the macro reads every capture group before the closure's code")
        }
        throw Unconvertible(reason: "it passes \(match.name) on to other code")
    }
}
#endif
