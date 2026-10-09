//
//  StepDefinitionCall+RegexReads.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

// What the closure of a regex literal step definition reads from its `Regex.Match`.
extension StepDefinitionCall {
    /// `let name[: Substring] = match.1` or `match.output.1`: the capture group, counted from 1.
    static func regexRead(_ item: CodeBlockItemSyntax, match: String) -> (name: String, group: Int)? {
        guard let declaration = item.item.as(VariableDeclSyntax.self),
              declaration.bindingSpecifier.tokenKind == .keyword(.let),
              declaration.attributes.isEmpty, declaration.modifiers.isEmpty,
              declaration.bindings.count == 1, let binding = declaration.bindings.first,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              binding.typeAnnotation.map({ $0.type.trimmedDescription == "Substring" }) ?? true,
              let access = binding.initializer?.value.as(MemberAccessExprSyntax.self),
              let group = Int(access.declName.baseName.text), group >= 1,
              let base = access.base else { return nil }
        let isMatch = base.as(DeclReferenceExprSyntax.self)?.baseName.text == match
        let isOutput = base.as(MemberAccessExprSyntax.self).map {
            $0.declName.baseName.text == "output" && $0.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == match
        } ?? false
        return isMatch || isOutput ? (name, group) : nil
    }

    /// The statements at the top of the closure that read a capture group, in any order: a group is read
    /// whole and never throws, so the macro's order of reading changes nothing.
    func regexReads(in closure: ClosureExprSyntax, match: Parameter, pattern: StepPattern) throws -> [Read] {
        guard match.name != "_" else { return [] }
        var reads = [Read]()
        for item in closure.statements {
            guard let read = Self.regexRead(item, match: match.name) else { break }
            guard read.group <= pattern.captures.count else {
                throw Unconvertible(reason: "it reads capture group \(read.group), and its pattern has \(pattern.captures.count)")
            }
            guard !reads.contains(where: { $0.capture == read.group - 1 }) else {
                throw Unconvertible(reason: "it reads capture group \(read.group) more than once")
            }
            reads.append(Read(name: read.name, type: nil, capture: read.group - 1))
        }
        return reads
    }
}
#endif
