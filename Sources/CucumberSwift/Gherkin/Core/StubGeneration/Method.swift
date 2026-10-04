//
//  Method.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/4/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
class Method {
    /// What makes an XCTest step definition fail until it is filled in.
    static let xcTestFailure = "XCTFail(\"Step not implemented: replace this line with your test code\")"

    var keyword: Step.Keyword = []
    var keywords: [Step.Keyword] = []
    var comment = ""
    /// The step definition's pattern as Swift source, such as `"I see {int} messages"` or `#/^I see (\d+) messages$/#`.
    private(set) var pattern = ""
    /// A regular expression for the step, to find the implemented steps this step definition would also match.
    private(set) var regex = ""
    private(set) var matchesParameter = ""
    /// Each parameter, in the order of the step: its variable's type name and the Swift code that reads it.
    private(set) var captures: [(type: String, value: String)] = []
    private(set) var variables: [(type: String, count: Int)] = []
    init(keyword: Step.Keyword,
         pattern: String,
         regex: String,
         matchesParameter: String,
         captures: [(type: String, value: String)],
         variables: [(type: String, count: Int)]) {
        self.keyword = keyword
        self.keywords = [keyword]
        self.pattern = pattern
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

    /// The step definition as Swift. `failure` is its last line, which fails the step until it is filled in.
    func generateSwift(matchAllAllowed: Bool = true, failure: String = xcTestFailure) -> String {
        Scope.language ?= Language()
        var methodStrings = [String]()
        for keywordString in getKeywordStrings(matchAllAllowed: matchAllAllowed) {
            // swiftlint:disable:next empty_count
            let variablesOnStepObject = variables.filter { $0.type == "dataTable" || $0.type == "docString" }.filter { $0.count > 0 }
            let stepParameter = (!variablesOnStepObject.isEmpty) ? "step" : "_"
            var methodString = "\(keywordString.capitalizingFirstLetter())(\(pattern)) { \(matchesParameter), \(stepParameter) in\n"
            var countByType = [String: Int]()
            for capture in captures {
                let count = countByType[capture.type, default: 0] + 1
                countByType[capture.type] = count
                methodString += "    let \(Self.variableName(type: capture.type, number: count)) = \(capture.value)\n"
            }
            for variable in variablesOnStepObject {
                methodString += "    let \(Self.variableName(type: variable.type, number: 1)) = step.\(variable.type)\n"
            }
            // An empty step would pass, so the stub fails until it is filled in.
            methodString += "    \(failure)\n"
            methodString += "}"
            methodStrings.append(methodString)
        }
        return comment + methodStrings.joined(separator: "\n")
    }
}
