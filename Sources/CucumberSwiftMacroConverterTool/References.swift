//
//  References.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

/// Every use of a name as an expression, such as `match` in `match.first(\.int)`. Not a member of the
/// same name, such as `.match`.
final class References: SyntaxVisitor {
    private let name: String
    private var found = [DeclReferenceExprSyntax]()

    init(of name: String) {
        self.name = name
        super.init(viewMode: .sourceAccurate)
    }

    func uses(in node: Syntax) -> [DeclReferenceExprSyntax] {
        walk(node)
        return found
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        let isMemberName = node.parent?.as(MemberAccessExprSyntax.self)?.declName.id == node.id
        if node.baseName.text == name, !isMemberName { found.append(node) }
        return .visitChildren
    }
}
#endif
