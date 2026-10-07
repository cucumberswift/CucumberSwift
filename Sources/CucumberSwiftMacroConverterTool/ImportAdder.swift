//
//  ImportAdder.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftSyntax

/// Adds `import CucumberSwiftMacros` on the line after the first import from `CucumberSwift`.
final class ImportAdder: SyntaxRewriter {
    private let module: String
    private let adding: String
    private var added = false

    init(after module: String, adding: String) {
        self.module = module
        self.adding = adding
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let node = super.visit(node)
        guard !added, let index = node.firstIndex(where: { item in
            item.item.as(ImportDeclSyntax.self)?.path.first?.name.text == module
        }) else { return node }
        added = true
        let existing = node[index]
        // The same indentation as the import it follows, on a line of its own.
        let indentation = existing.leadingTrivia.pieces.reversed().prefix { !$0.isNewline }.reversed()
        let declaration = ImportDeclSyntax(
            importKeyword: .keyword(.import, leadingTrivia: Trivia(pieces: [.newlines(1)] + indentation), trailingTrivia: .space),
            path: ImportPathComponentListSyntax([ImportPathComponentSyntax(name: .identifier(adding))]))
        var items = Array(node)
        items.insert(CodeBlockItemSyntax(item: .decl(DeclSyntax(declaration))), at: items.index(after: items.firstIndex { $0.id == existing.id } ?? 0))
        return CodeBlockItemListSyntax(items)
    }
}
#endif
