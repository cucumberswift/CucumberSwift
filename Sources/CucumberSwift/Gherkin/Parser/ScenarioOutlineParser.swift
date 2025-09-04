//
//  ScenarioOutlineParser.swift
//  CucumberSwift
//
//  Created by dev1 on 7/17/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

enum ScenarioOutlineParser {
    static func parse(_ scenarioOutlineNode: AST.ScenarioOutlineNode, featureTags: [String], backgroundStepNodes: [AST.StepNode], uri: String = "") -> [Scenario] {
        let tags = featureTags.appending(contentsOf: scenarioOutlineNode.tokens.compactMap {
            if case Lexer.Token.tag(_, let tag) = $0 {
                return tag
            }
            return nil
        })
        let stepNodes = scenarioOutlineNode.children.compactMap { $0 as? AST.StepNode }
        let outlineDescription = extractOutlineDescription(scenarioOutlineNode, stepNodes: stepNodes)
        return getExamplesFrom(scenarioOutlineNode)
            .flatMap { parseExample(titleLine: scenarioOutlineNode
                                            .tokens
                                            .groupedByLine()
                                            .first,
                                    tokens: $0,
                                    outlineTags: tags,
                                    stepNodes: stepNodes,
                                    backgroundStepNodes: backgroundStepNodes,
                                    description: outlineDescription,
                                    uri: uri)
            }
    }

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

    static func getExamplesFrom(_ scenarioOutlineNode: AST.ScenarioOutlineNode) -> [[Lexer.Token]] {
        scenarioOutlineNode.tokens.drop { !$0.isExampleScope() }.groupedByExample()
    }

    private static func validateTable(_ lines: [[Lexer.Token]], uri: String) {
        guard let header = lines.first else { return }
        if lines.contains(where: { $0.count != header.count }) {
            Gherkin.errors.append("File: \(uri) inconsistent cell count within the table")
        }
    }

    private static func parseExample(titleLine: [Lexer.Token]?,
                                     tokens: [Lexer.Token],
                                     outlineTags: [String],
                                     stepNodes: [AST.StepNode],
                                     backgroundStepNodes: [AST.StepNode],
                                     description: String,
                                     uri: String) -> [Scenario] {
        var scenarios = [Scenario]()
        let lines = tokens.filter { $0.isTableCell() || $0.isNewline() }.groupedByLine()
        validateTable(lines, uri: uri)
        let headerLookup: [String: Int]? = lines.first?.enumerated().reduce(into: [:]) {
            if case Lexer.Token.tableCell(_, let headerText) = $1.element {
                $0?[headerText.valueDescription] = $1.offset
            }
        }
        let tags = outlineTags
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
            var steps = backgroundStepNodes.map { Step(with: $0) }
            for stepNode in stepNodes {
                steps.append(getStepFromLine(line, lookup: headerLookup, stepNode: stepNode))
            }
            let exampleNumber = index + 1
            scenarios.append(Scenario(with: steps, title: "\(title) (example \(exampleNumber))", description: description, tags: tags, position: line.first?.position ?? .start))
        }
        return scenarios
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
