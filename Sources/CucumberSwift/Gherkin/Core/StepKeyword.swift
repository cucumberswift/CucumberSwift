//
//  StepKeyword.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 4/7/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

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

extension Step.Keyword {
    /// For each of a scenario's steps, in order, the primary keyword (`Given`, `When` or `Then`) that it
    /// continues, or `nil`. An `And`, `But` or `*` step continues the last primary keyword before it, and
    /// step definitions for that keyword match it too.
    static func continuedKeywords(_ keywords: [Step.Keyword]) -> [Step.Keyword?] {
        var previous: Step.Keyword?
        return keywords.map { keyword in
            let continued = primaryKeywords.contains(keyword) ? nil : previous
            if primaryKeywords.contains(keyword) {
                previous = keyword
            }
            return continued
        }
    }
}
