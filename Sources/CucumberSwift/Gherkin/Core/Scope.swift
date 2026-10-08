//
//  Scope.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 4/8/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
enum Scope: Equatable, Hashable {
    static var language = Language() ?? Language.default

    case feature
    case background
    case scenario
    case scenarioOutline
    case step(Step.Keyword)
    case examples
    case rule
    case unknown

    /// The scope that `str` starts, read with the keywords of `language`. A step's keyword is the text it
    /// starts with, which may be several words or have no space after it, such as `Gegeben sei` or `前提`.
    static func scopeFor(str: String, in language: Language = Scope.language) -> Scope {
        if language.matchesFeature(str) {
            return .feature
        } else if language.matchesScenario(str) {
            return .scenario
        } else if language.matchesBackground(str) {
            return .background
        } else if language.matchesExamples(str) {
            return .examples
        } else if language.matchesScenarioOutline(str) {
            return .scenarioOutline
        } else if language.matchesRule(str) {
            return .rule
        }
        if let written = language.stepKeyword(startingLine: str),
           let keyword = Step.Keyword(written, in: language) {
            return .step(keyword)
        }
        return .unknown
    }

    static func == (lhs: Scope, rhs: Scope) -> Bool {
        switch (lhs, rhs) {
            case (.feature, .feature): return true
            case (.background, .background): return true
            case (.scenario, .scenario): return true
            case (.scenarioOutline, .scenarioOutline): return true
            case (.step(let s1), .step(let s2)): return s1 == s2
            case (.examples, .examples): return true
            case (.rule, .rule): return true
            case (.unknown, .unknown): return true
            default: return false
        }
    }

    func isStep() -> Bool {
        if case .step = self {
            return true
        }
        return false
    }
}
