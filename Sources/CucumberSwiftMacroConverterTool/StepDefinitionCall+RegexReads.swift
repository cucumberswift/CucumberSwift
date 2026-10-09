//
//  StepDefinitionCall+RegexReads.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

// What the closure of a regex literal step definition reads from its `Regex.Match`.
extension StepDefinitionCall {
    /// `let name[: Type] = match.1` or `match.output.1`, or a named group's name in place of its number. The
    /// read's `capture` is the group's index in the pattern's captures: the group's number less 1.
    static func regexRead(_ item: CodeBlockItemSyntax, match: String, pattern: StepPattern) -> Read? {
        guard let declaration = item.item.as(VariableDeclSyntax.self),
              declaration.bindingSpecifier.tokenKind == .keyword(.let),
              declaration.attributes.isEmpty, declaration.modifiers.isEmpty,
              declaration.bindings.count == 1, let binding = declaration.bindings.first,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let access = binding.initializer?.value.as(MemberAccessExprSyntax.self),
              let base = access.base else { return nil }
        let member = access.declName.baseName.text
        // A named group's parameter is its name; an unnamed one's is `anonymous`, which a group can't be named.
        let named = pattern.captures.firstIndex { $0.parameter == member && member != "anonymous" }.map { $0 + 1 }
        guard let group = Int(member) ?? named, group >= 1 else { return nil }
        let isMatch = base.as(DeclReferenceExprSyntax.self)?.baseName.text == match
        let isOutput = base.as(MemberAccessExprSyntax.self).map {
            $0.declName.baseName.text == "output" && $0.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == match
        } ?? false
        return isMatch || isOutput ? Read(name: name, type: binding.typeAnnotation?.type, capture: group - 1) : nil
    }

    /// The statements at the top of the closure that read a capture group, in any order: a group is read
    /// whole and never throws, so the macro's order of reading changes nothing.
    func regexReads(in closure: ClosureExprSyntax, match: Parameter, pattern: StepPattern) throws -> [Read] {
        guard match.name != "_" else { return [] }
        var reads = [Read]()
        for item in closure.statements {
            guard let read = Self.regexRead(item, match: match.name, pattern: pattern) else { break }
            let group = read.capture + 1
            guard read.capture < pattern.captures.count else {
                throw Unconvertible(reason: "it reads capture group \(group), and its pattern has \(pattern.captures.count)")
            }
            guard !reads.contains(where: { $0.capture == read.capture }) else {
                throw Unconvertible(reason: "it reads capture group \(group) more than once")
            }
            if let declared = read.type?.trimmedDescription, let expected = pattern.captures[read.capture].type,
               declared != expected, declared != "Swift.\(expected)" {
                throw Unconvertible(reason: "it declares capture group \(group) as \(declared), and the macro gives it as \(expected)")
            }
            reads.append(read)
        }
        return reads
    }
}
#endif
