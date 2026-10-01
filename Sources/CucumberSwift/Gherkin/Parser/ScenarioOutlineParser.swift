//
//  ScenarioOutlineParser.swift
//  CucumberSwift
//
//  Created by dev1 on 7/17/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

enum ScenarioOutlineParser {
    /// What every example of one Scenario Outline shares.
    private struct Outline {
        let titleLine: [Lexer.Token]?
        let tags: [String]
        let stepNodes: [AST.StepNode]
        let backgroundStepNodes: [AST.StepNode]
        let description: String
        let uri: String
    }

    /// The longest the example's values may make its title, in characters. The title names the test
    /// Xcode runs, and Xcode cannot save an attachment whose file name that makes too long (#100).
    static let maximumValuesLength = 60

    /**
     Extracts the description text for a scenario outline by processing its tokens.
     
     The algorithm follows these steps:
     1. Collect tokens up to (but not including) the first `Examples` block.
     2. Identify the first step line number to ensure the description stops before any steps begin.
     3. Build lines of description text from the collected tokens, preserving intentional blank lines.
     4. Trim leading and trailing empty lines while preserving inner spacing.
     
     The resulting string is the final description text used for each generated scenario.
     */
    private static func extractOutlineDescription(_ scenarioOutlineNode: AST.ScenarioOutlineNode, stepNodes: [AST.StepNode]) -> String {
        // Collect tokens up to (but not including) the first Examples block
        let tokensUpToExamples = scenarioOutlineNode.tokens.prefix { !$0.isExampleScope() }

        // Determine the first step line (if any) so we stop before steps
        let firstStepLine: UInt? = stepNodes
            .compactMap { $0.tokens.first?.position.line }
            .min()

        // Group tokens into lines and drop the title line
        let lines = Array(tokensUpToExamples).groupedByLine().dropFirst()

        var descLines: [String] = []
        for line in lines {
            // If we have a first step, stop collecting when we reach it
            if let firstStepLine, let lineNo = line.first?.position.line, lineNo >= firstStepLine {
                break
            }
            // Skip pure newlines
            let nonNewline = line.contains { !$0.isNewline() }
            guard nonNewline else { continue }

            // Build textual content from tokens on this line (only `.description` tokens)
            let buffer = line.compactMap { tok -> String? in
                if tok.isNewline() { return nil }
                if case let .description(_, t) = tok { return t.description }
                return nil
            }
                .joined()
            // Keep the line even if empty, to preserve intentional blank lines
            descLines.append(buffer)
        }

        // Trim leading/trailing empty lines while preserving inner spacing
        let trimmed = descLines
            .drop { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            .reversed()
            .drop { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            .reversed()

        guard !trimmed.isEmpty else { return "" }
        return trimmed.joined(separator: "\n") + "\n"
    }

    static func parse(_ scenarioOutlineNode: AST.ScenarioOutlineNode, featureTags: [String], backgroundStepNodes: [AST.StepNode], uri: String = "") -> [Scenario] {
        let tags = featureTags.appending(contentsOf: scenarioOutlineNode.tokens.compactMap {
            if case Lexer.Token.tag(_, let tag) = $0 {
                return tag
            }
            return nil
        })
        let stepNodes = scenarioOutlineNode.children.compactMap { $0 as? AST.StepNode }
        let outline = Outline(titleLine: scenarioOutlineNode.tokens.groupedByLine().first,
                              tags: tags,
                              stepNodes: stepNodes,
                              backgroundStepNodes: backgroundStepNodes,
                              description: extractOutlineDescription(scenarioOutlineNode, stepNodes: stepNodes),
                              uri: uri)
        // Shared by every Examples block, so no two examples of the outline get the same title.
        var usedTitles = Set<String>()
        return getExamplesFrom(scenarioOutlineNode)
            .flatMap { parseExample($0, of: outline, usedTitles: &usedTitles) }
    }

    static func getExamplesFrom(_ scenarioOutlineNode: AST.ScenarioOutlineNode) -> [[Lexer.Token]] {
        scenarioOutlineNode.tokens.drop { !$0.isExampleScope() }.groupedByExample()
    }

    private static func validateTable(_ lines: [[Lexer.Token]], uri: String) {
        guard let header = lines.first else { return }
        if lines.contains(where: { $0.count != header.count }) {
            Gherkin.errors.append("File: \(uri) inconsistent cell count within the table")
        }
    }

    private static func parseExample(_ tokens: [Lexer.Token], of outline: Outline, usedTitles: inout Set<String>) -> [Scenario] {
        let titleLine = outline.titleLine
        var scenarios = [Scenario]()
        let lines = tokens.filter { $0.isTableCell() || $0.isNewline() }.groupedByLine()
        validateTable(lines, uri: outline.uri)
        let headerLookup: [String: Int]? = lines.first?.enumerated().reduce(into: [:]) {
            if case Lexer.Token.tableCell(_, let headerText) = $1.element {
                $0?[headerText.valueDescription] = $1.offset
            }
        }
        let headers = lines.first?.compactMap { token -> String? in
            guard case Lexer.Token.tableCell(_, let headerText) = token else { return nil }
            return headerText.valueDescription
        } ?? []
        let headersInTitle = Set(titleLine?.compactMap { token -> String? in
            guard case Lexer.Token.tableHeader(_, let headerText) = token else { return nil }
            return headerText
        } ?? [])
        for (index, line) in lines.dropFirst().enumerated() {
            let title = titleLine?.reduce(into: "") {
                if case Lexer.Token.tableHeader(_, let headerText) = $1 {
                    if let index = headerLookup?[headerText],
                        index < line.count,
                        index >= 0,
                        case Lexer.Token.tableCell(_, let cellText) = line[index] {
                        $0? += cellText.valueDescription
                    }
                } else if case Lexer.Token.title(_, let titleText) = $1 {
                    $0? += titleText
                }
            } ?? ""
            var steps = outline.backgroundStepNodes.map { Step(with: $0) }
            for stepNode in outline.stepNodes {
                steps.append(getStepFromLine(line, lookup: headerLookup, stepNode: stepNode))
            }
            let values = zip(headers, line).compactMap { header, cell -> String? in
                guard !headersInTitle.contains(header), case Lexer.Token.tableCell(_, let cellText) = cell else { return nil }
                return "\(header): \(cellText.valueDescription)"
            }
            let exampleTitle = exampleTitle(title, values: values, exampleNumber: index + 1, usedTitles: &usedTitles)
            scenarios.append(Scenario(with: steps, title: exampleTitle, description: outline.description, tags: outline.tags, position: line.first?.position ?? .start))
        }
        return scenarios
    }

    /// An example's title: the outline's title followed by the example's values for the columns the
    /// title does not already use, as in `Sign in (email: bob@x.com, role: admin)`. Values that would
    /// pass ``maximumValuesLength`` are left out, and an ellipsis shows that some are. An example whose
    /// title would repeat an earlier one's, in any of the outline's Examples blocks, also gets its
    /// number, and a further count if that is taken too, so every example has its own name.
    static func exampleTitle(_ title: String, values: [String], exampleNumber: Int, usedTitles: inout Set<String>) -> String {
        var valueList = ""
        for value in values {
            let next = valueList.isEmpty ? value : "\(valueList), \(value)"
            guard next.count <= maximumValuesLength else {
                valueList = valueList.isEmpty ? String(value.prefix(maximumValuesLength - 1)) + "…" : "\(valueList), …"
                break
            }
            valueList = next
        }
        var exampleTitle = valueList.isEmpty ? title : "\(title) (\(valueList))"
        if valueList.isEmpty || usedTitles.contains(exampleTitle) {
            exampleTitle = valueList.isEmpty ? "\(title) (example \(exampleNumber))" : "\(title) (\(valueList), example \(exampleNumber))"
        }
        // A cell can itself read like the number, as in "a, example 3", so count on until the title is new.
        let numbered = exampleTitle
        var attempt = 1
        while usedTitles.contains(exampleTitle) {
            attempt += 1
            exampleTitle = "\(numbered) \(attempt)"
        }
        usedTitles.insert(exampleTitle)
        return exampleTitle
    }

    private static func getStepFromLine(_ line: [Lexer.Token], lookup: [String: Int]?, stepNode: AST.StepNode) -> Step {
        let node = AST.StepNode(node: stepNode)
        for (i, token) in node.tokens.enumerated() {
            if case Lexer.Token.tableHeader(_, let headerText) = token,
               let index = lookup?[headerText],
               let cell = line[safe: index],
               case Lexer.Token.tableCell(let pos, let cellText) = cell {
                node.tokens[i] = .match(pos, cellText.valueDescription)
            } else if case Lexer.Token.tableCell(_, let cellToken) = token,
                      case Lexer.Token.tableHeader(_, let headerText) = cellToken,
                      let index = lookup?[headerText],
                      let cell = line[safe: index],
                      case Lexer.Token.tableCell(let pos, let cellText) = cell {
                node.tokens[i] = .tableCell(pos, .match(cellToken.position, cellText.valueDescription))
            }
        }
        return Step(with: node)
    }
}

extension Sequence where Element == Lexer.Token {
    fileprivate func groupedByExample() -> [[Lexer.Token]] {
        var examples = [[Lexer.Token]]()
        var example = [Lexer.Token]()
        for token in self {
            if token.isExampleScope() && !example.isEmpty {
                examples.append(example)
                example.removeAll()
            } else {
                example.append(token)
            }
        }
        if !example.isEmpty {
            examples.append(example)
        }
        return examples
    }
}
