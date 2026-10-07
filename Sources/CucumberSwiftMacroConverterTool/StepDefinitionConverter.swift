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
        /// imported. Exactly the source given when nothing was converted.
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
        return Result(source: rewriter.converted.isEmpty ? source : rewritten.description,
                      converted: rewriter.converted,
                      leftUnchanged: rewriter.leftUnchanged)
    }
}

// MARK: Which runner the file uses

/// The runner a file imports, which decides the macros' module and whether localized macros exist.
private struct Runner {
    struct Found {
        /// `CucumberSwift` or `CucumberSwiftTesting`.
        let module: String
        let macrosModule: String
        let importsMacros: Bool
        var hasLocalizedMacros: Bool { module == "CucumberSwift" }
    }

    let found: Found?
    /// Why no step definition in the file can be converted, when the imports don't say which runner it uses.
    let problem: String?

    init(importsOf tree: SourceFileSyntax) {
        let modules = Set(ImportCollector(viewMode: .sourceAccurate).modules(in: tree))
        let runners = [("CucumberSwift", "CucumberSwiftMacros"), ("CucumberSwiftTesting", "CucumberSwiftTestingMacros")]
            .filter { modules.contains($0.0) || modules.contains($0.1) }
        switch runners.count {
            case 1:
                let (module, macrosModule) = runners[0]
                found = Found(module: module, macrosModule: macrosModule, importsMacros: modules.contains(macrosModule))
                problem = nil
            case 0:
                found = nil
                problem = "the file imports neither CucumberSwift nor CucumberSwiftTesting, so it isn't clear which macros to use"
            default:
                found = nil
                problem = "the file imports both CucumberSwift and CucumberSwiftTesting, so it isn't clear which macros to use"
        }
    }
}

private final class ImportCollector: SyntaxVisitor {
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

/// Adds `import CucumberSwiftMacros` on the line after the first import from `CucumberSwift`.
private final class ImportAdder: SyntaxRewriter {
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

// MARK: Finding and converting step definitions

private final class Rewriter: SyntaxRewriter {
    private let runner: Runner
    private let converter: SourceLocationConverter
    private(set) var converted = [StepDefinitionConverter.Entry]()
    private(set) var leftUnchanged = [StepDefinitionConverter.Entry]()

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
}

private struct Unconvertible: Error {
    let reason: String
}

/// One step definition call, checked and converted.
private struct StepDefinitionCall {
    /// What a read statement reads: the parameter's key path, and its index when it reads by position.
    struct Source {
        let name: String
        let type: TypeSyntax?
        let parameter: String
        let index: Int?
    }

    /// A parameter read at the top of the closure: `let count: Int = try match.first(\.int)`.
    struct Read {
        let name: String
        let type: TypeSyntax?
        let capture: Int
    }

    let call: FunctionCallExprSyntax
    let keyword: String
    let runner: Runner

    init(_ call: FunctionCallExprSyntax, keyword: String, runner: Runner) {
        self.call = call
        self.keyword = keyword
        self.runner = runner
    }

    func macro() throws -> MacroExpansionExprSyntax {
        guard let found = runner.found else { throw Unconvertible(reason: runner.problem ?? "") }
        if StepDefinitionConverter.localizedNames.contains(keyword), !found.hasLocalizedMacros {
            throw Unconvertible(reason: "\(found.macrosModule) has no localized macros")
        }
        let (pattern, closure) = try arguments()
        let parameters = try closureParameters(closure)
        let reads = try self.reads(in: closure, match: parameters.match, pattern: pattern)
        let rest = closure.statements.dropFirst(reads.count)
        try checkTheRest(rest, match: parameters.match)

        var clause = [String]()
        var names = [String]()
        for (index, capture) in pattern.captures.enumerated() {
            let read = reads.first { $0.capture == index }
            let name = read?.name ?? "_"
            guard let type = try parameterType(of: read, capture: capture) else {
                throw Unconvertible(reason: "it doesn't read {\(capture.parameter)}, a custom parameter type, so the macro's closure can't be given its type")
            }
            clause.append("\(name): \(type)")
            names.append(name)
        }
        if parameters.step.name != "_" {
            clause.append("\(parameters.step.name): \(parameters.step.type?.trimmedDescription ?? "Step")")
            names.append(parameters.step.name)
        }
        // The expansion names the Match `match`, or `match2` and so on when a parameter has that name.
        var hidden = "match"
        var number = 2
        while names.contains(hidden) {
            hidden = "match\(number)"
            number += 1
        }
        if !pattern.captures.isEmpty, Self.references(hidden, in: rest) {
            throw Unconvertible(reason: "its closure uses `\(hidden)`, which the macro's expansion would hide behind its own `\(hidden)`")
        }

        let newClosure = try rewritten(closure, parameters: clause, droppingReads: reads.count)
        return makeMacro(closure: newClosure)
    }

    // MARK: Arguments

    private func arguments() throws -> (StepPattern, ClosureExprSyntax) {
        let arguments = Array(call.arguments)
        let labels = arguments.dropFirst().compactMap { $0.label?.text }
        if labels.contains("class") {
            throw Unconvertible(reason: "it calls a selector, and the macros take a closure")
        }
        if let other = labels.first(where: { $0 != "callback" }) {
            throw Unconvertible(reason: "it passes `\(other):`, which the macros don't take")
        }
        let expression = arguments[0].expression
        if expression.is(RegexLiteralExprSyntax.self) {
            throw Unconvertible(reason: "its pattern is a regex literal, and the macros take a string")
        }
        guard let literal = expression.as(StringLiteralExprSyntax.self), let text = literal.representedLiteralValue else {
            throw Unconvertible(reason: "its pattern isn't a string literal")
        }
        let pattern: StepPattern
        do {
            pattern = try StepPattern(text)
        } catch let problem as StepPattern.Problem {
            throw Unconvertible(reason: "its pattern has a mistake the macro would report: \(problem.message)")
        }
        let body = call.trailingClosure.map { ExprSyntax($0) } ?? arguments.dropFirst().first?.expression
        guard let closure = body?.as(ClosureExprSyntax.self), call.additionalTrailingClosures.isEmpty else {
            throw Unconvertible(reason: "it passes a function, and the macros take a closure")
        }
        return (pattern, closure)
    }

    // MARK: The closure's parameters

    private struct Parameter {
        let name: String
        let type: TypeSyntax?
    }

    private func closureParameters(_ closure: ClosureExprSyntax) throws -> (match: Parameter, step: Parameter) {
        let parameters: [Parameter]
        switch closure.signature?.parameterClause {
            case .simpleInput(let list):
                parameters = list.map { Parameter(name: $0.name.text, type: nil) }
            case .parameterClause(let clause):
                parameters = clause.parameters.map { Parameter(name: ($0.secondName ?? $0.firstName).text, type: $0.type) }
            case nil:
                throw Unconvertible(reason: "its closure uses $0 and $1, and the macros name each argument")
        }
        guard parameters.count == 2 else {
            throw Unconvertible(reason: "its closure doesn't take a Match and a Step")
        }
        if let type = parameters[0].type?.trimmedDescription, type != "Match", type != "CucumberSwiftExpressions.Match" {
            throw Unconvertible(reason: type.replacingOccurrences(of: " ", with: "") == "[String]"
                ? "it uses the deprecated [String] closure"
                : "its closure's first argument is \(type), not a Match")
        }
        return (parameters[0], parameters[1])
    }

    // MARK: Reading the parameters

    /// The statements at the top of the closure that read a parameter the way the expansion does.
    private func reads(in closure: ClosureExprSyntax, match: Parameter, pattern: StepPattern) throws -> [Read] {
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

    /// `let name[: Type] = try match.first(\.parameter)` or `let name[: Type] = match[\.parameter, index: n]`.
    private static func read(_ item: CodeBlockItemSyntax, match: String) -> Source? {
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
    private static func keyPathParameter(_ expression: ExprSyntax) -> String? {
        guard let keyPath = expression.as(KeyPathExprSyntax.self), keyPath.root == nil,
              keyPath.components.count == 1,
              let property = keyPath.components.first?.component.as(KeyPathPropertyComponentSyntax.self),
              property.genericArgumentClause == nil else { return nil }
        return property.declName.baseName.text
    }

    /// The type the macro's closure gives the parameter: the one the read declares, or the built-in one.
    private func parameterType(of read: Read?, capture: StepPattern.Capture) throws -> String? {
        guard let declared = read?.type?.trimmedDescription else { return capture.type }
        if let expected = capture.type, declared != expected, declared != "Swift.\(expected)" {
            throw Unconvertible(reason: "it declares {\(capture.parameter)} as \(declared), and the macro gives it as \(expected)")
        }
        return declared
    }

    // MARK: The rest of the closure

    private func checkTheRest(_ rest: some Sequence<CodeBlockItemSyntax>, match: Parameter) throws {
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
        throw Unconvertible(reason: "it passes \(match.name) on to other code")
    }

    private static func isMember(_ use: DeclReferenceExprSyntax, named name: String) -> Bool {
        use.parent?.as(MemberAccessExprSyntax.self)?.declName.baseName.text == name
    }

    private static func isIntegerSubscript(_ use: DeclReferenceExprSyntax) -> Bool {
        guard let subscriptCall = use.parent?.as(SubscriptCallExprSyntax.self) else { return false }
        return subscriptCall.arguments.count == 1 && subscriptCall.arguments.first?.expression.is(IntegerLiteralExprSyntax.self) == true
    }

    private static func references(_ name: String, in rest: some Sequence<CodeBlockItemSyntax>) -> Bool {
        rest.contains { !References(of: name).uses(in: Syntax($0)).isEmpty }
    }

    // MARK: Rewriting

    private func rewritten(_ closure: ClosureExprSyntax, parameters: [String], droppingReads count: Int) throws -> ClosureExprSyntax {
        var closure = closure
        if let signature = closure.signature {
            let old = signature.parameterClause
            if parameters.isEmpty {
                let bare = signature.with(\.parameterClause, nil)
                if bare.attributes.isEmpty, bare.capture == nil, bare.effectSpecifiers == nil, bare.returnClause == nil {
                    closure.signature = nil
                    // `{ _, _ in` on its own line becomes `{`, without a space before the line break.
                    if closure.statements.first?.leadingTrivia.first?.isNewline ?? true {
                        closure.leftBrace = closure.leftBrace.with(\.trailingTrivia, [])
                    }
                } else {
                    closure.signature = bare
                }
            } else {
                // Parsed as part of a closure, the only place the parser accepts closure parameters.
                let parsed = Parser.parse(source: "{ (\(parameters.joined(separator: ", "))) in }")
                guard !parsed.hasError,
                      let clause = parsed.statements.first?.item.as(ClosureExprSyntax.self)?.signature?.parameterClause?
                        .as(ClosureParameterClauseSyntax.self) else {
                    throw Unconvertible(reason: "its closure's new parameters, \(parameters.joined(separator: ", ")), don't parse")
                }
                closure.signature = signature.with(\.parameterClause, .parameterClause(clause
                    .with(\.leadingTrivia, old?.leadingTrivia ?? [])
                    .with(\.trailingTrivia, old?.trailingTrivia ?? .space)))
            }
        }
        guard count > 0 else { return closure }

        let removed = closure.statements.prefix(count)
        let comments = removed.flatMap { item in
            item.tokens(viewMode: .sourceAccurate).flatMap { ($0.leadingTrivia + $0.trailingTrivia).pieces.filter(\.isComment) }
        }
        let indentation = Self.indentation(of: removed.first?.leadingTrivia ?? [])
        var kept = Array(closure.statements.dropFirst(count))
        // Each comment on a line of its own, where the reads were.
        let carried = comments.flatMap { [TriviaPiece.newlines(1)] + indentation + [$0] }
        if var first = kept.first {
            var trivia = first.leadingTrivia.pieces
            if carried.isEmpty, trivia.first?.isNewline == true {
                // The reads are gone, and with them the blank line that set them apart from the code.
                trivia = [.newlines(1)] + indentation + trivia.drop { $0.isWhitespace }
            }
            first.leadingTrivia = Trivia(pieces: carried + trivia)
            kept[0] = first
        } else {
            closure.rightBrace.leadingTrivia = Trivia(pieces: carried) + closure.rightBrace.leadingTrivia
        }
        closure.statements = CodeBlockItemListSyntax(kept)
        return closure
    }

    /// The spaces and tabs after the last line break.
    private static func indentation(of trivia: Trivia) -> [TriviaPiece] {
        Array(trivia.pieces.reversed().prefix { !$0.isNewline }.reversed().filter { $0.isSpaceOrTab })
    }

    private func makeMacro(closure: ClosureExprSyntax) -> MacroExpansionExprSyntax {
        var arguments = Array(call.arguments)
        if call.trailingClosure == nil, arguments.count == 2 {
            // `Given("…", callback: { … })` becomes `#Given("…", { … })`, as the macros don't label it.
            arguments[1] = arguments[1].with(\.label, nil).with(\.colon, nil)
                .with(\.expression, ExprSyntax(closure).with(\.leadingTrivia, arguments[1].label?.leadingTrivia ?? []))
        }
        let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName ?? .identifier(keyword)
        return MacroExpansionExprSyntax(
            leadingTrivia: name.leadingTrivia,
            pound: .poundToken(),
            macroName: name.with(\.leadingTrivia, []),
            leftParen: call.leftParen,
            arguments: LabeledExprListSyntax(arguments),
            rightParen: call.rightParen,
            trailingClosure: call.trailingClosure == nil ? nil : closure,
            additionalTrailingClosures: call.additionalTrailingClosures)
    }
}

/// Every use of a name as an expression, such as `match` in `match.first(\.int)`. Not a member of the
/// same name, such as `.match`.
private final class References: SyntaxVisitor {
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

extension TriviaPiece {
    fileprivate var isComment: Bool {
        switch self {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment: return true
            default: return false
        }
    }

    fileprivate var isSpaceOrTab: Bool {
        switch self {
            case .spaces, .tabs: return true
            default: return false
        }
    }
}
#endif
