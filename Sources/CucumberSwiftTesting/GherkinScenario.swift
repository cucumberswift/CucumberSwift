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
    /// The keyword in the feature file's language, for messages.
    public let keywordName: String
    public let text: String
    public let line: Int
    public let column: Int
    public let docString: DocString?
    public let dataTable: [[String]]?
    /// The step definition to suggest if no step definition matches the step.
    public let suggestion: String

    public init(
        keyword: Step.Keyword,
        keywordName: String,
        text: String,
        line: Int,
        column: Int,
        docString: DocString? = nil,
        dataTable: [[String]]? = nil,
        suggestion: String
    ) {
        self.keyword = keyword
        self.keywordName = keywordName
        self.text = text
        self.line = line
        self.column = column
        self.docString = docString
        self.dataTable = dataTable
        self.suggestion = suggestion
    }
}

/// One example of a Scenario Outline: one test case of the outline's parameterized test.
public struct GherkinExample: Sendable, CustomTestStringConvertible, CustomTestArgumentEncodable {
    public let scenario: GherkinScenario

    /// How Xcode and `swift test` name the test case: as CucumberSwift names the example's scenario.
    public var testDescription: String { scenario.title }

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
    public let title: String
    /// The feature's tags, then the scenario's, and an outline's Examples blocks'.
    public let tags: [String]
    /// The feature file's path on the Mac that built the tests.
    public let file: String
    public let line: Int
    public let column: Int
    /// The Background's steps, then the scenario's.
    public let steps: [GherkinStep]

    public init(
        featureTitle: String,
        featureTags: [String],
        title: String,
        tags: [String],
        file: String,
        line: Int,
        column: Int,
        steps: [GherkinStep]
    ) {
        self.featureTitle = featureTitle
        self.featureTags = featureTags
        self.title = title
        self.tags = tags
        self.file = file
        self.line = line
        self.column = column
        self.steps = steps
    }
}
