//
//  GherkinScenario.swift
//  CucumberSwiftTesting
//
// What the tests that CucumberSwiftTestingPlugin generates pass to the runner. They are public only so
// that the generated code, which is compiled into your test target, can use them.

import Foundation
import Testing

/// A step as its feature file describes it.
public struct GherkinStep: Sendable {
    public let keyword: Step.Keyword
    /// The keyword as written in the feature file, such as `Dado` or `And`, for messages.
    public let keywordName: String
    /// The keyword the step counts as, in the file's language: an `And` step's is the one it continues.
    /// The camel-case names of its tests use it. English when the generator didn't give one.
    public let keywordText: String
    public let text: String
    public let line: Int
    public let column: Int
    public let docString: DocString?
    public let dataTable: [[String]]?
    /// The step definition to suggest if no step definition matches the step.
    public let suggestion: String
    /// The same step definition with a regex literal, for ``Cucumber/generateRegexLiterals``.
    public let regexLiteralSuggestion: String?
    /// The same step definition with a bare slash regex literal, for ``RegexLiteralStyle/bareSlash``.
    public let bareSlashRegexLiteralSuggestion: String?

    public init(
        keyword: Step.Keyword,
        keywordName: String,
        keywordText: String? = nil,
        text: String,
        line: Int,
        column: Int,
        docString: DocString? = nil,
        dataTable: [[String]]? = nil,
        suggestion: String,
        regexLiteralSuggestion: String? = nil,
        bareSlashRegexLiteralSuggestion: String? = nil
    ) {
        self.keyword = keyword
        self.keywordName = keywordName
        self.keywordText = keywordText ?? Self.englishKeywordText(keyword, written: keywordName)
        self.text = text
        self.line = line
        self.column = column
        self.docString = docString
        self.dataTable = dataTable
        self.suggestion = suggestion
        self.regexLiteralSuggestion = regexLiteralSuggestion
        self.bareSlashRegexLiteralSuggestion = bareSlashRegexLiteralSuggestion
    }
}

/// One example of a Scenario Outline: one test case of the outline's parameterized test.
public struct GherkinExample: Sendable, CustomTestStringConvertible, CustomTestArgumentEncodable {
    public let scenario: GherkinScenario

    /// How Xcode and `swift test` name the test case: by its row's line, not its values. Xcode keeps
    /// the name from the first run after it indexes the tests, and shows a later result only on a
    /// row with the same name, so a name with the values would keep a stale row when one changes.
    public var testDescription: String { "Example (line \(scenario.line))" }

    public init(_ scenario: GherkinScenario) {
        self.scenario = scenario
    }

    /// Identifies the test case by its row's line only, so that changing a value in the row still
    /// lets Xcode run the case again.
    public func encodeTestArgument(to encoder: some Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(scenario.line)
    }
}

/// A scenario as its feature file describes it. Each example of a Scenario Outline is one.
public struct GherkinScenario: Sendable {
    public let featureTitle: String
    public let featureTags: [String]
    /// The text under the feature's title, for the report.
    public let featureDescription: String
    /// The line of the feature's `Feature:` keyword, for the report.
    public let featureLine: Int
    public let title: String
    /// The feature's tags, then the scenario's, and an outline's Examples blocks'.
    public let tags: [String]
    /// The feature file's path on the Mac that built the tests.
    public let file: String
    public let line: Int
    public let column: Int
    /// The Background's steps, then the scenario's.
    public let steps: [GherkinStep]
    /// Which scenario of the Swift DSL this is, or `nil` for one from a feature file. The examples of a
    /// `ScenarioOutline` in the DSL share a line, so this tells them apart.
    var dslID: Int?

    public init(
        featureTitle: String,
        featureTags: [String],
        featureDescription: String = "",
        featureLine: Int = 1,
        title: String,
        tags: [String],
        file: String,
        line: Int,
        column: Int,
        steps: [GherkinStep]
    ) {
        self.featureTitle = featureTitle
        self.featureTags = featureTags
        self.featureDescription = featureDescription
        self.featureLine = featureLine
        self.title = title
        self.tags = tags
        self.file = file
        self.line = line
        self.column = column
        self.steps = steps
    }
}

extension GherkinStep {
    private static func englishKeywordText(_ keyword: Step.Keyword, written: String) -> String {
        if keyword.contains(.given) { return "Given" }
        if keyword.contains(.when) { return "When" }
        if keyword.contains(.then) { return "Then" }
        if keyword.contains(.and) { return "And" }
        if keyword.contains(.but) { return "But" }
        return written
    }
}
