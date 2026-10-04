//
//  Step.swift
//  CucumberSwiftTesting
//
// What step definitions and hooks see, named as in CucumberSwift, so that the same step definitions
// work with both runners.

import Foundation

/// Where something is in a feature file.
public struct Location: Hashable, Sendable {
    public let line: Int
    public let column: Int
}

/// A step's doc string: the text between its `"""` or ```` ``` ```` lines.
public struct DocString: Hashable, Sendable {
    /// The text without the delimiters' indentation.
    public let literal: String
    /// The text as written.
    public let rawLiteral: String
    /// The text after the opening delimiter, such as `json`, if there is any.
    public let contentType: String?

    public init(literal: String, rawLiteral: String, contentType: String?) {
        self.literal = literal
        self.rawLiteral = rawLiteral
        self.contentType = contentType
    }
}

/// A step's data table.
public final class DataTable {
    public typealias Row = [String]
    public let rows: [Row]

    init(_ rows: [Row]) {
        self.rows = rows
    }
}

/// A step of a scenario, as step definitions and hooks see it.
public final class Step {
    /// The step's text, after its keyword.
    public let match: String
    /// The step's keyword. An `And`, `But` or `*` step also has the `Given`, `When` or `Then` it continues.
    public let keyword: Keyword
    public let docString: DocString?
    public let dataTable: DataTable?
    public let location: Location
    public private(set) weak var scenario: Scenario?
    let keywordName: String
    let suggestion: String

    /// The scenario's tags.
    public var tags: [String] { scenario?.tags ?? [] }

    init(_ step: GherkinStep, in scenario: Scenario) {
        match = step.text
        keyword = step.keyword
        docString = step.docString
        dataTable = step.dataTable.map(DataTable.init)
        location = Location(line: step.line, column: step.column)
        keywordName = step.keywordName
        suggestion = step.suggestion
        self.scenario = scenario
    }
}

extension Step {
    /// A step's keyword. Step definitions for a keyword match the steps whose keyword contains it.
    public struct Keyword: OptionSet, Hashable, Sendable {
        public static let given = Keyword(rawValue: 1 << 0)
        public static let when = Keyword(rawValue: 1 << 1)
        public static let then = Keyword(rawValue: 1 << 2)
        public static let and = Keyword(rawValue: 1 << 3)
        public static let but = Keyword(rawValue: 1 << 4)
        public static let primaryKeywords: Keyword = [.given, .when, .then]

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}
