//
//  StepDefinitionConverter.swift
//  CucumberSwiftMacroConverterTool
//

#if Macros
import SwiftParser
import SwiftSyntax

/// Rewrites step definitions such as `Given("…") { match, step in … }` as step definition macros, such
/// as `#Given("…") { (count: Int, step: Step) in … }`, when the macro expands to exactly the step
/// definition it replaces. That is when the closure reads each parameter at its top, in the pattern's
/// order, the way the macro's expansion reads it, and uses `match` for nothing else. Every other step
/// definition is left as it is, with the reason.
public enum StepDefinitionConverter {
    /// A step definition the converter found, and what it did with it.
    public struct Entry: Equatable {
        /// The step definition's line in the source it was given.
        public let line: Int
        /// The step definition's keyword and pattern, as written: `Given("I have {int} cukes")`.
        public let stepDefinition: String
        /// Why it was left unchanged. `nil` when it was converted.
        public let reason: String?
    }

    public struct Result {
        /// The source with every step definition it could convert rewritten, and the macros' module
        /// imported, and a `#warning` before each step definition it left that stands alone as a statement.
        /// Exactly the source given when nothing changed.
        public let source: String
        public let converted: [Entry]
        public let leftUnchanged: [Entry]
    }

    /// The English keywords, which both runners have a macro for.
    static let keywords: Set<String> = ["Given", "When", "Then", "And", "But", "MatchAll"]

    /// The localized step definitions, such as `ES_Dado`, from the list that CucumberSwiftLintTool shares.
    static let localizedNames = Set(StepDefinition.localizedNames)

    public static func convert(_ source: String) -> Result {
        let tree = Parser.parse(source: source)
        let runner = Runner(importsOf: tree)
        let rewriter = Rewriter(runner: runner, converter: SourceLocationConverter(fileName: "", tree: tree))
        var rewritten = rewriter.rewrite(tree).cast(SourceFileSyntax.self)
        if !rewriter.converted.isEmpty, let runner = runner.found, !runner.importsMacros {
            rewritten = ImportAdder(after: runner.module, adding: runner.macrosModule).rewrite(rewritten).cast(SourceFileSyntax.self)
        }
        let changed = !rewriter.converted.isEmpty || rewritten.description != source
        return Result(source: changed ? rewritten.description : source,
                      converted: rewriter.converted,
                      leftUnchanged: rewriter.leftUnchanged)
    }
}
#endif
