//
//  ImportCollector.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

final class ImportCollector: SyntaxVisitor {
    private var found = [String]()

    func modules(in tree: SourceFileSyntax) -> [String] {
        walk(tree)
        return found
    }

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        if let module = node.path.first?.name.text { found.append(module) }
        return .skipChildren
    }
}
#endif
