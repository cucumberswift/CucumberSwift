//
//  Method.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/4/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
class Method {
    var keyword: Step.Keyword = []
    var keywords: [Step.Keyword] = []
    var comment = ""
    private(set) var regex = ""
    private(set) var matchesParameter = ""
    private(set) var captures: [String] = []
    private(set) var variables: [(type: String, count: Int)] = []
    init(keyword: Step.Keyword, regex: String, matchesParameter: String, captures: [String], variables: [(type: String, count: Int)]) {
        self.keyword = keyword
        self.keywords = [keyword]
        self.regex = regex
        self.matchesParameter = matchesParameter
        self.captures = captures
        self.variables = variables
    }

    /// `string`, `stringTwo`, `stringThree`, …
    private static func variableName(type: String, number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en-US")
        let spelledNumber = (number > 1) ? formatter.string(from: .init(value: number)) ?? "" : ""
        return "\(type) \(spelledNumber)".camelCasingString()
    }

    func insertKeyword(_ keyword: Step.Keyword) {
        keywords.append(keyword)
        self.keyword.insert(keyword)
    }

    private func getKeywordStrings(matchAllAllowed: Bool) -> [String] {
        var keywordStrings = [String]()
        if keyword.primaryKeywords.hasMultipleValues() && matchAllAllowed {
            keywordStrings.append("MatchAll")
        } else if !matchAllAllowed && keyword.primaryKeywords.hasMultipleValues() {
            keywordStrings.append(contentsOf: keywords.map { $0.primaryKeywords.toString() })
        } else {
            keywordStrings.append(keyword.primaryKeywords.toString())
        }
        return keywordStrings.uniqueElements
    }

    func generateSwift(matchAllAllowed: Bool = true, regexLiteralStyle: RegexLiteralStyle = .extendedDelimiter) -> String {
        Scope.language ?= Language()
        let pattern = "^\(regex.trimmingCharacters(in: .whitespacesAndNewlines))$"
        // The pattern escapes every `/`, so neither delimiter can end the literal early.
        let literal: String
        switch regexLiteralStyle {
            case .bareSlash: literal = "/\(pattern)/"
            case .extendedDelimiter: literal = "#/\(pattern)/#"
        }
        var methodStrings = [String]()
        for keywordString in getKeywordStrings(matchAllAllowed: matchAllAllowed) {
            // swiftlint:disable:next empty_count
            let variablesOnStepObject = variables.filter { $0.type == "dataTable" || $0.type == "docString" }.filter { $0.count > 0 }
            let stepParameter = (!variablesOnStepObject.isEmpty) ? "step" : "_"
            var methodString = "\(keywordString.capitalizingFirstLetter())(\(literal)) { \(matchesParameter), \(stepParameter) in\n"
            // A regex literal's match holds the whole match at .0 and each capture at .1, .2, …
            var countByType = [String: Int]()
            for (position, type) in captures.enumerated() {
                let count = countByType[type, default: 0] + 1
                countByType[type] = count
                methodString += "    let \(Self.variableName(type: type, number: count)) = \(matchesParameter).\(position + 1)\n"
            }
            for variable in variablesOnStepObject {
                methodString += "    let \(Self.variableName(type: variable.type, number: 1)) = step.\(variable.type)\n"
            }
            if captures.isEmpty && variablesOnStepObject.isEmpty {
                methodString += "\n"
            }
            methodString += "}"
            methodStrings.append(methodString)
        }
        return comment + methodStrings.joined(separator: "\n")
    }
}
