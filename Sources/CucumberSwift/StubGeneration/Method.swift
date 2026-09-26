//
//  Method.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/4/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
@MainActor
class Method {
    var keyword: Step.Keyword = []
    var keywords: [Step.Keyword] = []
    var comment = ""
    private(set) var regex = ""
    private(set) var matchesParameter = ""
    private(set) var variables: [(type: String, count: Int)] = []
    init(keyword: Step.Keyword, regex: String, matchesParameter: String, variables: [(type: String, count: Int)]) {
        self.keyword = keyword
        self.keywords = [keyword]
        self.regex = regex
        self.matchesParameter = matchesParameter
        self.variables = variables
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

    @MainActor
    func generateSwift(matchAllAllowed: Bool = true) -> String {
        Scope.language ?= Language()
        var methodStrings = [String]()
        for keywordString in getKeywordStrings(matchAllAllowed: matchAllAllowed) {
            // swiftlint:disable:next empty_count
            let variablesOnStepObject = variables.filter { $0.type == "dataTable" || $0.type == "docString" }.filter { $0.count > 0 }
            let stepParameter = (!variablesOnStepObject.isEmpty) ? "step" : "_"
            var methodString = "\(keywordString.capitalizingFirstLetter())(/^\(regex.trimmingCharacters(in: .whitespacesAndNewlines))$/) { \(matchesParameter), \(stepParameter) in\n"
            for variable in variables {
                for i in 0..<variable.count {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .spellOut
                    formatter.locale = Locale(identifier: "en-US")
                    let spelledNumber = (i > 0) ? formatter.string(from: .init(value: i + 1)) ?? "" : ""
                    let varName = "\(variable.type) \(spelledNumber)".camelCasingString()
                    if variable.type != "dataTable" && variable.type != "docString" {
                        methodString += "    let \(varName) = \(matchesParameter)[\(i + 1)]\n"
                    } else {
                        methodString += "    let \(varName) = step.\(variable.type)\n"
                    }
                }
            }
            if variables.reduce(0, { $0 + $1.count }) <= 0 {
                methodString += "\n"
            }
            methodString += "}"
            methodStrings.append(methodString)
        }
        return comment + methodStrings.joined(separator: "\n")
    }
}
