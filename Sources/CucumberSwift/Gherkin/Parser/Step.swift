//
//  Step.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 4/7/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

public class Step: CustomStringConvertible {
    public var description: String {
        "TAGS:\(tags)\n\(keywordText): \(match)"
    }

    public var continueAfterFailure = true {
        willSet {
            testCase?.continueAfterFailure = newValue
        }
    }

    public var canExecute: Bool {
        execute != nil
            || executeSelector != nil
            || executeClass != nil
    }

    public private(set)  var match = ""
    public private(set)  var keyword: Keyword = []
    public internal(set) var tags = [String]()
    public internal(set) var scenario: Scenario?
    public internal(set) var dataTable: DataTable?
    public private(set)  var docString: DocString?
    public private(set)  var location: Lexer.Position
    public internal(set) var testCase: XCTestCase?

    typealias MatchesExpression = ((_ str: String) -> Bool)
    typealias Execute = ((_ match: String, _ steps: Step) throws -> Void)
    typealias AsyncExecute = @MainActor (_ match: String, _ steps: Step) async throws -> Void

    var result: Reporter.Result = .pending
    var execute: Execute?
    /// The body of an async step definition. `execute` then runs it and waits for it to finish.
    var executeAsync: AsyncExecute?
    var executeSelector: Selector?
    var executeClass: AnyClass?
    var executeInstance: NSObject?
    var matchesExpression: MatchesExpression?
    var errorMessage: String = ""
    var startTime: Date?
    var endTime: Date?
    var executionDuration: Measurement<UnitDuration> {
        // Converting to nanoseconds from seconds has a rounding error, so storing as nanoseconds is actually better.
        guard let start = startTime, let end = endTime else { return Measurement(value: 0, unit: .seconds) }
        if #available(iOS 13.0, macOS 10.15, tvOS 13, *) {
            return Measurement(value: end.timeIntervalSince(start) * 1_000_000_000, unit: .nanoseconds)
        } else {
            return Measurement(value: end.timeIntervalSince(start), unit: .seconds)
        }
    }
    var tokens = [Lexer.Token]()
    var sourceLine: Int?
    var sourceFile: StaticString?
    /// A step definition that matches this step: where it was registered, and what it matches and runs.
    /// One instance per registration, shared by every step it matches, so it can be counted once.
    final class Definition {
        let file: StaticString
        let line: Int
        let matches: MatchesExpression
        let execute: Execute?
        /// The body of an async step definition, which `execute` runs and waits for.
        let executeAsync: AsyncExecute?

        init(file: StaticString, line: Int, matches: @escaping MatchesExpression, execute: Execute?, executeAsync: AsyncExecute? = nil) {
            self.file = file
            self.line = line
            self.matches = matches
            self.execute = execute
            self.executeAsync = executeAsync
        }
    }
    /// Every step definition that matches this step. A step that more than one step definition
    /// matches is ambiguous: it fails and runs none of them.
    var matchingDefinitions = [Definition]()
    var isAmbiguous: Bool { matchingDefinitions.count > 1 }
    /// The language of the feature file the step comes from. Its keyword is named in this language, not in
    /// the one the lexer last read, which is the last feature file's.
    let language: Language
    /// The step's keyword as written in its feature file: `And` or `But` rather than the keyword it
    /// continues, which ``keyword`` also holds.
    var writtenKeyword: String {
        if keyword.contains(.and) { return language.and }
        if keyword.contains(.but) { return language.but }
        return keywordText
    }
    /// The step's ``keyword`` named in its feature file's language.
    var keywordText: String {
        keyword.toString(in: language)
    }

    /// A step parsed from a feature file. Steps are built straight after their file is lexed, so the lexer's
    /// language is still that file's.
    init(with node: AST.StepNode, language: Language = Scope.language) {
        self.language = language
        location = node.tokens.first { $0.isKeyword() }?.position ?? .start
        tokens = node.tokens.filter { !$0.isKeyword() }
        for token in node.tokens {
            if case Lexer.Token.keyword(_, let kw) = token {
                keyword = kw
            } else if case Lexer.Token.match(_, let m) = token {
                match += m
            } else if case Lexer.Token.tableHeader(_, let h) = token {
                match += h
            } else if case Lexer.Token.docString(_, let s) = token {
                docString = s
            }
        }
        let tableLines = node.tokens
            .filter { $0.isTableCell() || $0.isNewline() }
            .groupedByLine()
            .map { line -> [String] in
                line.filter { $0.isTableCell() }
                    .map { token -> String in
                        if case Lexer.Token.tableCell(_, let cellToken) = token {
                            if case Lexer.Token.tableHeader = cellToken {
                                return "<\(cellToken.valueDescription)>"
                            }
                            return cellToken.valueDescription
                        }
                        return ""
                    }
            }
        if !tableLines.isEmpty {
            dataTable = DataTable(tableLines)
        }
        match = match.trimmingCharacters(in: .whitespaces)
    }

    /// A step written in the Swift DSL, whose keywords are English.
    init(with execute: @escaping (([String], Step) -> Void), match: String?, position: Lexer.Position) {
        language = .default
        location = position
        self.match ?= match
        self.execute = { _, step in
            // Steps built this way come from the Swift DSL, which has no regex and therefore no
            // capture groups. Passing "" to `matches(for:)` here used to compile an empty pattern
            // on every execution, which always throws and always yielded [] anyway.
            execute([], step)
        }
    }

    func addPrimaryKeyword(_ keyword: Keyword) throws {
        guard Keyword.primaryKeywords.contains(keyword) else {
            throw Keyword.KeywordError.notPrimaryKeyword
        }
        self.keyword.insert(keyword)
    }

    func toJSON() -> [String: Any] {
        if #available(iOS 13.0, macOS 10.15, tvOS 13, *) {
            return [
                "result": ["status": "\(result)", "error_message": errorMessage, "duration": executionDuration.converted(to: .nanoseconds).value],
                "name": "\(match)",
                "keyword": "\(keywordText)"
            ]
        } else {
            return [
                "result": ["status": "\(result)", "error_message": errorMessage, "duration": executionDuration.converted(to: .seconds).value * 1_000_000_000],
                "name": "\(match)",
                "keyword": "\(keywordText)"
            ]
        }
    }
}

extension Step {
    public struct Keyword: OptionSet, Hashable, Sendable {
        public let rawValue: Int
        var primaryKeywords: Keyword {
            intersection(Self.primaryKeywords)
        }
        private var stringValue: String?
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public init?(_ str: String) {
            stringValue = str
            var set: Keyword = []
            if Scope.language.matchesGiven(str) {
                set.insert(.given)
            }
            if Scope.language.matchesWhen(str) {
                set.insert(.when)
            }
            if Scope.language.matchesThen(str) {
                set.insert(.then)
            }
            if Scope.language.matchesAnd(str) {
                set.insert(.and)
            }
            if Scope.language.matchesBut(str) {
                set.insert(.but)
            }
            guard !set.isEmpty else { return nil }
            self = set
        }

        /// The keyword named in the language of the feature file the lexer last read. A step's own keyword
        /// is named in its feature file's language.
        public func toString() -> String {
            toString(in: Scope.language)
        }

        public func hasMultipleValues() -> Bool {
            guard rawValue > 2 else { return false }
            return ceil(log2(Double(rawValue))) != floor(log2(Double(rawValue)))
        }

        public static let given = Keyword(rawValue: 1 << 0)
        public static let when = Keyword(rawValue: 1 << 1)
        public static let then = Keyword(rawValue: 1 << 2)
        public static let and = Keyword(rawValue: 1 << 3)
        public static let but = Keyword(rawValue: 1 << 4)
        public static let primaryKeywords: Keyword = [.given, .when, .then]

        enum KeywordError: Error {
            case notPrimaryKeyword
        }
    }
}

extension Step.Keyword {
    /// The keyword named in the given language.
    func toString(in language: Language) -> String {
        if let str = stringValue {
            return str
        }
        if contains(.given) {
            return language.given
        }
        if contains(.when) {
            return language.when
        }
        if contains(.then) {
            return language.then
        }
        if contains(.and) {
            return language.and
        }
        if contains(.but) {
            return language.but
        }
        return "UNKNOWN"
    }
}
