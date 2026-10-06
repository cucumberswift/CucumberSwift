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
        enum KeywordError: Error {
            case notPrimaryKeyword
        }

        public static let given = Keyword(rawValue: 1 << 0)
        public static let when = Keyword(rawValue: 1 << 1)
        public static let then = Keyword(rawValue: 1 << 2)
        public static let and = Keyword(rawValue: 1 << 3)
        public static let but = Keyword(rawValue: 1 << 4)
        public static let primaryKeywords: Keyword = [.given, .when, .then]

        public let rawValue: Int
        var primaryKeywords: Keyword {
            intersection(Self.primaryKeywords)
        }
        private var stringValue: String?

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public init?(_ str: String) {
            self.init(str, in: Scope.language)
        }

        /// The keyword `str` names in `language`.
        init?(_ str: String, in language: Language) {
            var set: Keyword = []
            if language.matchesGiven(str) {
                set.insert(.given)
            }
            if language.matchesWhen(str) {
                set.insert(.when)
            }
            if language.matchesThen(str) {
                set.insert(.then)
            }
            if language.matchesAnd(str) {
                set.insert(.and)
            }
            if language.matchesBut(str) {
                set.insert(.but)
            }
            guard !set.isEmpty else { return nil }
            self = set
            stringValue = str
        }

        /// The keyword as it is written in the feature file it was read from, such as `Given`, `And` or `Dado`.
        /// A step's `And` or `But` keyword stays as written after the parser adds the keyword it continues.
        /// A keyword with no written form, such as ``given`` or one built by a set operation like `union`, is
        /// named in the language of the feature file the lexer last read.
        public func toString() -> String {
            if let str = stringValue {
                return str
            }
            return toString(in: Scope.language)
        }

        public func hasMultipleValues() -> Bool {
            guard rawValue > 2 else { return false }
            return ceil(log2(Double(rawValue))) != floor(log2(Double(rawValue)))
        }
    }
}

extension Step.Keyword {
    /// This keyword with `other`'s keywords added, still written as this one is. `insert` would forget how
    /// it is written, as every set operation does.
    func adding(_ other: Step.Keyword) -> Step.Keyword {
        var keyword = union(other)
        keyword.stringValue = stringValue
        return keyword
    }

    /// The keyword as it is written in its feature file, such as `Dado` or `Y` rather than the language's
    /// last form for it, or `And` rather than the keyword it continues. A keyword with no written form is
    /// named in the given language, an `And` or `But` keyword as itself.
    func written(in language: Language) -> String {
        if let str = stringValue {
            return str
        }
        if contains(.and) {
            return language.and
        }
        if contains(.but) {
            return language.but
        }
        return toString(in: language)
    }

    /// The keyword named in the given language, by the language's last form for it.
    func toString(in language: Language) -> String {
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
