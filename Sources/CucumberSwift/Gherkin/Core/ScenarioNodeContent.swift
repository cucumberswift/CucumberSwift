//
//  ScenarioNodeContent.swift
//  CucumberSwift
//

import Foundation

/// A scenario of a feature, as CucumberSwift runs it.
enum ScenarioNodeContent {
    /// A Scenario, and the Background steps that run before it: the feature's, then its Rule's.
    case scenario(AST.ScenarioNode, backgroundStepNodes: [AST.StepNode])
    /// A Scenario Outline, and its examples. Each example runs as a scenario of its own, after the
    /// Background's steps.
    case outline(AST.ScenarioOutlineNode, examples: [OutlineExample])
}

extension AST.FeatureNode {
    private static func backgroundSteps(of node: AST.Node) -> [AST.StepNode] {
        node.children
            .compactMap { $0 as? AST.BackgroundNode }
            .flatMap { $0.children.compactMap { $0 as? AST.StepNode } }
    }

    /// The feature's scenarios, in the order they are written. A Rule's Scenarios are in its place. A
    /// Scenario Outline inside a Rule is left out.
    func scenarioContents(featureTags: [String], uri: String = "") -> [ScenarioNodeContent] {
        let backgroundSteps = Self.backgroundSteps(of: self)
        return children.flatMap { node -> [ScenarioNodeContent] in
            if let scenarioNode = node as? AST.ScenarioNode {
                return [.scenario(scenarioNode, backgroundStepNodes: backgroundSteps)]
            } else if let outlineNode = node as? AST.ScenarioOutlineNode {
                let examples = ScenarioOutlineParser.examples(
                    of: outlineNode,
                    featureTags: featureTags,
                    backgroundStepNodes: backgroundSteps,
                    uri: uri)
                return [.outline(outlineNode, examples: examples)]
            } else if let ruleNode = node as? AST.RuleNode {
                let ruleBackgroundSteps = backgroundSteps.appending(contentsOf: Self.backgroundSteps(of: ruleNode))
                return ruleNode.children
                    .compactMap { $0 as? AST.ScenarioNode }
                    .map { .scenario($0, backgroundStepNodes: ruleBackgroundSteps) }
            }
            return []
        }
    }
}
