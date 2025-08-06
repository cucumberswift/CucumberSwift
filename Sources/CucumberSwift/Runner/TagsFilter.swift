//
//  TagsFilter.swift
//  CucumberSwift
//
//  
//  Copyright © 2025 Tyler Thompson. All rights reserved.
//

import Foundation

/// A utility class for evaluating tag filter expressions in Cucumber scenarios.
/// Supports logical operators: and, or, not, and parentheses for grouping.
public class TagsFilter {

    /// Evaluates whether a scenario should run based on the provided tag filter expression.
    /// - Parameters:
    ///   - filterExpression: A string expression like "not dev and (smoke or integration)"
    ///   - scenarioTags: The tags associated with the scenario
    /// - Returns: true if the scenario should run, false otherwise
    public static func shouldRun(filterExpression: String?, scenarioTags: [String]) -> Bool {
        // If no filter expression is provided, run all scenarios
        guard let expression = filterExpression, !expression.isEmpty else { return true }

        // Parse and evaluate the tag expression
        return evaluateTagExpression(expression, scenarioTags: scenarioTags)
    }

    private static func evaluateTagExpression(_ expression: String, scenarioTags: [String]) -> Bool {
        // Convert to lowercase for case-insensitive parsing
        let normalizedExpression = expression.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle empty expression
        if normalizedExpression.isEmpty {
            return true
        }

        // Convert scenario tags to lowercase for case-insensitive comparison
        // Remove @ prefixes if present and trim whitespace
        let lowercaseScenarioTags = scenarioTags.map {
            $0.lowercased()
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .replacingOccurrences(of: "@", with: "")
        }

        // Parse the expression using a simple recursive descent parser
        return parseOrExpression(normalizedExpression, scenarioTags: lowercaseScenarioTags).result
    }

    private static func parseOrExpression(_ expression: String, scenarioTags: [String]) -> (result: Bool, remaining: String) {
        var (result, remaining) = parseAndExpression(expression, scenarioTags: scenarioTags)

        while remaining.hasPrefix("or ") {
            let nextExpression = String(remaining.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            let (nextResult, nextRemaining) = parseAndExpression(nextExpression, scenarioTags: scenarioTags)
            result = result || nextResult
            remaining = nextRemaining
        }

        return (result, remaining)
    }

    private static func parseAndExpression(_ expression: String, scenarioTags: [String]) -> (result: Bool, remaining: String) {
        var (result, remaining) = parseNotExpression(expression, scenarioTags: scenarioTags)

        while remaining.hasPrefix("and ") {
            let nextExpression = String(remaining.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            let (nextResult, nextRemaining) = parseNotExpression(nextExpression, scenarioTags: scenarioTags)
            result = result && nextResult
            remaining = nextRemaining
        }

        return (result, remaining)
    }

    private static func parseNotExpression(_ expression: String, scenarioTags: [String]) -> (result: Bool, remaining: String) {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("not ") {
            let nextExpression = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            let (result, remaining) = parsePrimaryExpression(nextExpression, scenarioTags: scenarioTags)
            return (!result, remaining)
        }

        return parsePrimaryExpression(trimmed, scenarioTags: scenarioTags)
    }

    private static func parsePrimaryExpression(_ expression: String, scenarioTags: [String]) -> (result: Bool, remaining: String) {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)

        // Handle parentheses
        if trimmed.hasPrefix("(") {
            let content = String(trimmed.dropFirst())
            var parenCount = 1
            var endIndex = 0

            for (index, char) in content.enumerated() {
                if char == "(" {
                    parenCount += 1
                } else if char == ")" {
                    parenCount -= 1
                    if parenCount == 0 {
                        endIndex = index
                        break
                    }
                }
            }

            let innerExpression = String(content.prefix(endIndex))
            let remaining = String(content.dropFirst(endIndex + 1)).trimmingCharacters(in: .whitespaces)
            let result = evaluateTagExpression(innerExpression, scenarioTags: scenarioTags)

            return (result, remaining)
        }

        // Handle simple tag
        let components = trimmed.components(separatedBy: .whitespaces)
        guard let tag = components.first, !tag.isEmpty else {
            return (true, "")
        }

        let remaining = components.dropFirst().joined(separator: " ")

        // Clean tag name (remove @ prefix if present, trim whitespace, convert to lowercase)
        let cleanTag = tag.replacingOccurrences(of: "@", with: "")
                     .trimmingCharacters(in: .whitespacesAndNewlines)
                     .lowercased()

        // The scenario tags are already cleaned in evaluateTagExpression
        let result = scenarioTags.contains(cleanTag)

        return (result, remaining)
    }
}
