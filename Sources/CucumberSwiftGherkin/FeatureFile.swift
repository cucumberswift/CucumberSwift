//
//  FeatureFile.swift
//  CucumberSwiftGherkin
//
// The files in Core are CucumberSwift's own Gherkin parser, from Sources/CucumberSwift/Gherkin/Core,
// compiled a second time here without XCTest so that build tools can use it. This file and
// Keywords.swift are the only API this module offers them.

import Foundation

/// The namespace of CucumberSwift's `Step` class, which declares `Step.Keyword`. Build tools have no
/// steps to run, so here it is only a namespace.
enum Step {}

/// A feature file, read by CucumberSwift's Gherkin parser: what a build tool needs to know about each
/// feature, scenario and step, as CucumberSwift reads them.
public struct FeatureFile: Equatable, Sendable {
    public let features: [Feature]
    /// Problems the parser found, such as an unsupported `# language:`, in the words CucumberSwift
    /// reports them.
    public let problems: [String]

    /// Parses `text`. `uri` names the file in problems. Safe to call from several threads at once: one
    /// file is parsed at a time.
    public init(parsing text: String, uri: String) {
        let parsed = Gherkin.parsing {
            // The lexer sets the language from the file's `# language:` comment, and the steps must
            // be read before anything lexes another file, as CucumberSwift does.
            let tokens = Lexer(text, uri: uri).lex()
            return AST.standard.parse(tokens, inFile: uri).map { Feature($0, uri: uri) }
        }
        features = parsed.result
        problems = parsed.problems
    }
}

extension FeatureFile {
    public struct Feature: Equatable, Sendable {
        public let title: String
        /// The lines under the title, each followed by a newline.
        public let description: String
        public let tags: [String]
        public let line: Int
        public let column: Int
        /// The scenarios in the order they are written, a Rule's Scenarios and Scenario Outlines in its
        /// place.
        public let scenarios: [Scenario]
    }

    public struct Scenario: Equatable, Sendable {
        public let title: String
        public let description: String
        /// The feature's tags, then its Rule's, then the scenario's. For a Scenario Outline, each of its
        /// ``examples`` also has its own Examples block's tags.
        public let tags: [String]
        public let line: Int
        public let column: Int
        /// The feature's Background steps, then its Rule's, then the scenario's. Empty for a Scenario
        /// Outline: each of its ``examples`` has its own.
        public let steps: [Step]
        /// A Scenario Outline's examples, one for each row of its Examples tables. `nil` for a Scenario.
        public let examples: [Example]?
        /// The title of the Rule the scenario is in, or `nil` when it isn't in one.
        public let ruleTitle: String?
        /// The line of the Rule the scenario is in, or `nil` when it isn't in one.
        public let ruleLine: Int?
    }

    /// One row of a Scenario Outline's Examples table, which CucumberSwift runs as a scenario of its own.
    public struct Example: Equatable, Sendable {
        /// The outline's title with the row's values, as CucumberSwift names the scenario. Unique
        /// within the outline.
        public let title: String
        /// The feature's, the Rule's and the outline's tags, then those of the row's own Examples block.
        public let tags: [String]
        /// The row's line.
        public let line: Int
        public let column: Int
        /// The feature's and the Rule's Background steps, then the outline's, with the row's values in
        /// place of the `<placeholders>`.
        public let steps: [Step]
    }

    public struct Step: Equatable, Sendable {
        /// The keywords step definitions can match the step with: its own, and for an `And`, `But`
        /// or `*` step, the `Given`, `When` or `Then` it continues. `*` has all five of its own.
        public let keywords: Set<Keyword>
        /// The keyword as written in the feature file, such as `Dado` or `And`, as CucumberSwift names it in
        /// its messages.
        public let keywordName: String
        /// The keyword the step counts as, in the file's language: for an `And` or `But` step, the one it
        /// continues. CucumberSwift names the camel-case tests of a step after it.
        public let keywordText: String
        /// The step's text, after its keyword.
        public let text: String
        public let line: Int
        public let column: Int
        public let docString: DocString?
        /// The data table's rows, `nil` when the step has none.
        public let dataTable: [[String]]?
    }

    public enum Keyword: String, CaseIterable, Sendable {
        case given, when, then, and, but
    }

    /// A step's doc string, named as CucumberSwift's `DocString` names it.
    public struct DocString: Equatable, Sendable {
        /// The text between the delimiters, without their indentation.
        public let literal: String
        /// The text between the delimiters as written.
        public let rawLiteral: String
        /// The text after the opening delimiter, such as `json`, if there is any.
        public let contentType: String?
    }
}

// MARK: - Reading the parser's nodes

/// Parsing uses state the whole parser shares, `Scope.language` and `Gherkin.errors`, so one file is
/// parsed at a time.
private let parsingLock = NSLock()

extension Gherkin {
    /// Runs `body`, and returns what it returns with the problems the parser recorded meanwhile. No
    /// other file is parsed until it returns.
    fileprivate static func parsing<T>(_ body: () -> T) -> (result: T, problems: [String]) {
        parsingLock.lock()
        defer { parsingLock.unlock() }
        errors.removeAll()
        let result = body()
        let problems = errors.snapshot
        errors.removeAll()
        return (result, problems)
    }
}

extension FeatureFile.Feature {
    fileprivate init(_ node: AST.FeatureNode, uri: String) {
        let header = NodeHeader(node.tokens)
        let position = node.tokens.first?.position ?? .start
        title = header.title
        description = header.description
        tags = header.tags
        line = Int(position.line)
        column = Int(position.column)
        let featureTags = header.tags
        scenarios = node.scenarioContents(featureTags: featureTags, uri: uri).map { content in
            switch content {
                case let .scenario(scenarioNode, inheritedTags, backgroundStepNodes, rule):
                    let scenarioHeader = NodeHeader(scenarioNode.tokens)
                    let stepNodes = backgroundStepNodes + scenarioNode.children.compactMap { $0 as? AST.StepNode }
                    return FeatureFile.Scenario(
                        title: scenarioHeader.title,
                        description: scenarioHeader.description,
                        tags: inheritedTags + scenarioHeader.tags,
                        position: scenarioNode.tokens.first?.position ?? .start,
                        steps: .init(stepNodes),
                        examples: nil,
                        rule: rule)
                case let .outline(outlineNode, inheritedTags, examples, rule):
                    let outlineStepNodes = outlineNode.children.compactMap { $0 as? AST.StepNode }
                    let description = ScenarioOutlineParser.extractOutlineDescription(outlineNode, stepNodes: outlineStepNodes)
                    return FeatureFile.Scenario(
                        title: outlineTitle(outlineNode),
                        description: description,
                        tags: ScenarioOutlineParser.tags(of: outlineNode, featureTags: inheritedTags),
                        position: outlineNode.tokens.first?.position ?? .start,
                        steps: [],
                        examples: examples.map(FeatureFile.Example.init),
                        rule: rule)
            }
        }
    }
}

extension FeatureFile.Scenario {
    fileprivate init(
        title: String,
        description: String,
        tags: [String],
        position: Lexer.Position,
        steps: [FeatureFile.Step],
        examples: [FeatureFile.Example]?,
        rule: AST.RuleNode?
    ) {
        self.title = title
        self.description = description
        self.tags = tags
        line = Int(position.line)
        column = Int(position.column)
        self.steps = steps
        self.examples = examples
        ruleTitle = rule.map { NodeHeader($0.tokens).title }
        ruleLine = rule.map { Int($0.tokens.first?.position.line ?? 0) }
    }
}

extension FeatureFile.Example {
    fileprivate init(_ example: OutlineExample) {
        title = example.title
        tags = example.tags
        line = Int(example.position.line)
        column = Int(example.position.column)
        steps = .init(example.stepNodes)
    }
}

extension Array where Element == FeatureFile.Step {
    /// One scenario's steps, in order, so that each `And`, `But` or `*` step gets the keyword it continues.
    fileprivate init(_ nodes: [AST.StepNode]) {
        let contents = nodes.map(StepNodeContent.init)
        let continued = Step.Keyword.continuedKeywords(contents.map(\.keyword))
        self = zip(contents, continued).map { content, continued in
            FeatureFile.Step(content, keyword: continued.map { content.keyword.union($0) } ?? content.keyword)
        }
    }
}

extension FeatureFile.Step {
    fileprivate init(_ content: StepNodeContent, keyword: Step.Keyword) {
        keywords = Set(FeatureFile.Keyword.allCases.filter { keyword.contains(Step.Keyword($0)) })
        // Steps are read straight after their file is lexed, so the lexer's language is still the file's.
        keywordName = content.keyword.written(in: Scope.language)
        keywordText = keyword.toString(in: Scope.language)
        text = content.match
        line = Int(content.location.line)
        column = Int(content.location.column)
        docString = content.docString.map {
            FeatureFile.DocString(literal: $0.literal, rawLiteral: $0.rawLiteral, contentType: $0.contentType)
        }
        dataTable = content.tableRows.isEmpty ? nil : content.tableRows
    }
}

extension Step.Keyword {
    fileprivate init(_ keyword: FeatureFile.Keyword) {
        switch keyword {
            case .given: self = .given
            case .when: self = .when
            case .then: self = .then
            case .and: self = .and
            case .but: self = .but
        }
    }
}

// MARK: - Names and suggestions, as CucumberSwift makes them

extension FeatureFile {
    /// `title` as a Swift type name, as CucumberSwift names the classes of the tests it generates:
    /// `Pay with a gift card` is `PayWithAGiftCard`. Empty when `title` has no letters.
    public static func typeName(for title: String) -> String {
        title.toClassString()
    }
}

extension FeatureFile.Step {
    /// The step definition CucumberSwift suggests for this step when no step definition matches it,
    /// with a Cucumber Expression. `failure` is its last line, which fails the step until it is filled in.
    /// With `macro`, it is a step definition macro, such as `#Given("I have {int} cukes") { (int: Int) in`.
    public func suggestedStepDefinition(failure: String, macro: Bool = false) -> String {
        suggestedStepDefinition(failure: failure, style: .cucumberExpression, macro: macro)
    }

    /// The same step definition with a regex literal, written `#/…/#`, or `/…/` with `bareSlash`.
    public func suggestedRegexLiteralStepDefinition(failure: String, bareSlash: Bool, macro: Bool = false) -> String {
        suggestedStepDefinition(failure: failure, style: .regexLiteral(bareSlash ? .bareSlash : .extendedDelimiter), macro: macro)
    }

    private func suggestedStepDefinition(failure: String, style: StubGenerator.Style, macro: Bool) -> String {
        let keyword = keywords.reduce(into: Step.Keyword()) { $0.insert(Step.Keyword($1)) }
        return StubGenerator.method(for: text,
                                    keyword: keyword,
                                    hasDataTable: dataTable != nil,
                                    hasDocString: docString != nil,
                                    style: style,
                                    macro: macro)
            .generateSwift(failure: failure)
    }
}

/// The outline's title as written, with its `<placeholders>`.
private func outlineTitle(_ scenarioOutlineNode: AST.ScenarioOutlineNode) -> String {
    scenarioOutlineNode.tokens.groupedByLine().first?.reduce(into: "") {
        if case Lexer.Token.tableHeader(_, let headerText) = $1 {
            $0 += "<\(headerText)>"
        } else if case Lexer.Token.title(_, let titleText) = $1 {
            $0 += titleText
        }
    } ?? ""
}
