//
//  ScenarioNodeContent.swift
//  CucumberSwift
//

import Foundation

/// A scenario of a feature, as CucumberSwift runs it.
enum ScenarioNodeContent {
    /// A Scenario, the tags it inherits (the feature's, then its Rule's), and the Background steps that
    /// run before it: the feature's, then its Rule's.
    case scenario(AST.ScenarioNode, inheritedTags: [String], backgroundStepNodes: [AST.StepNode])
    /// A Scenario Outline, the tags it inherits, and its examples. Each example runs as a scenario of its
    /// own, after the Background's steps, with the inherited tags before its own.
    case outline(AST.ScenarioOutlineNode, inheritedTags: [String], examples: [OutlineExample])
}

extension AST.FeatureNode {
    private static func backgroundSteps(of node: AST.Node) -> [AST.StepNode] {
        node.children
            .compactMap { $0 as? AST.BackgroundNode }
            .flatMap { $0.children.compactMap { $0 as? AST.StepNode } }
    }

    /// The feature's scenarios, in the order they are written. A Rule's Scenarios and Scenario Outlines
    /// are in its place, after the feature's tags and Background, and the Rule's.
    func scenarioContents(featureTags: [String], uri: String = "") -> [ScenarioNodeContent] {
        Self.scenarioContents(of: self,
                              inheritedTags: featureTags,
                              backgroundSteps: Self.backgroundSteps(of: self),
                              uri: uri)
    }

    private static func scenarioContents(of parent: AST.Node,
                                         inheritedTags: [String],
                                         backgroundSteps: [AST.StepNode],
                                         uri: String) -> [ScenarioNodeContent] {
        parent.children.flatMap { node -> [ScenarioNodeContent] in
            if let scenarioNode = node as? AST.ScenarioNode {
                return [.scenario(scenarioNode, inheritedTags: inheritedTags, backgroundStepNodes: backgroundSteps)]
            } else if let outlineNode = node as? AST.ScenarioOutlineNode {
                let examples = ScenarioOutlineParser.examples(
                    of: outlineNode,
                    featureTags: inheritedTags,
                    backgroundStepNodes: backgroundSteps,
                    uri: uri)
                return [.outline(outlineNode, inheritedTags: inheritedTags, examples: examples)]
            } else if let ruleNode = node as? AST.RuleNode {
                return scenarioContents(of: ruleNode,
                                        inheritedTags: inheritedTags + NodeHeader(ruleNode.tokens).tags,
                                        backgroundSteps: backgroundSteps + Self.backgroundSteps(of: ruleNode),
                                        uri: uri)
            }
            return []
        }
    }
}
