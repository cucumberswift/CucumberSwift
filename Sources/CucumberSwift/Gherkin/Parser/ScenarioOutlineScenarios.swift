//
//  ScenarioOutlineScenarios.swift
//  CucumberSwift
//

import Foundation

extension Scenario {
    /// The scenario that runs one example of a Scenario Outline.
    convenience init(example: OutlineExample) {
        self.init(
            with: example.stepNodes.map { Step(with: $0) },
            title: example.title,
            description: example.description,
            tags: example.tags,
            position: example.position)
    }
}

extension ScenarioOutlineParser {
    /// A scenario for each example of the outline, in the order the Examples tables list them.
    static func parse(_ scenarioOutlineNode: AST.ScenarioOutlineNode, featureTags: [String], backgroundStepNodes: [AST.StepNode], uri: String = "") -> [Scenario] {
        examples(of: scenarioOutlineNode, featureTags: featureTags, backgroundStepNodes: backgroundStepNodes, uri: uri)
            .map { Scenario(example: $0) }
    }
}
