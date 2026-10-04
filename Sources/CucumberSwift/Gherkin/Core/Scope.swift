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

    static func scopeFor(str: String) -> Scope {
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
        let index = str.firstIndex(of: " ")
        let keywordString = String(str[str.startIndex..<(index ?? str.endIndex)])
        if let keyword = Step.Keyword(keywordString) {
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
