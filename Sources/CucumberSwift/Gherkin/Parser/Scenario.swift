//
//  Scenario.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 4/7/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
public class Scenario: NSObject, Taggable, Positionable {
    public private(set)  var title = ""
    public internal(set)  var tags = [String]()
    public internal(set)  var steps = [Step]()
    public internal(set) var desc: String = ""
    public internal(set) var feature: Feature?
    public private(set)  var location: Lexer.Position
    public private(set)  var endLocation: Lexer.Position
    internal var startDate = Date()

    init(with node: AST.ScenarioNode, tags: [String], stepNodes: [AST.StepNode]) {
        location = node.tokens.first?.position ?? .start
        endLocation = .start
        desc = ""
        super.init()
        self.tags = tags
        for token in node.tokens {
            if case Lexer.Token.title(_, let t) = token {
                title = t
            } else if case Lexer.Token.description(_, let t) = token {
                desc += t + "\n"
            } else if case Lexer.Token.tag(_, let tag) = token {
                self.tags.append(tag)
            }
        }
        steps ?= node.children.compactMap { $0 as? AST.StepNode }.map { Step(with: $0) }
        steps.insert(contentsOf: stepNodes.map { Step(with: $0) }, at: 0)
        setupSteps()
        endLocation ?= steps.last?.location
    }

    init(with steps: [Step], title: String?, description: String? = "", tags: [String], position: Lexer.Position) {
        location = position
        endLocation = position
        super.init()
        self.steps = steps
        self.title = title ?? ""
        self.desc = description ?? ""
        self.tags = tags
        setupSteps()
    }

    private func setupSteps() {
        // What happens with Background steps? Background is Given, step is And?
        var previousKeyword: Step.Keyword?
        self.steps.forEach { [weak self] in
            $0.scenario = self
            if let previous = previousKeyword, !Step.Keyword.primaryKeywords.contains($0.keyword) {
                try? $0.addPrimaryKeyword(previous)
            }
            if Step.Keyword.primaryKeywords.contains($0.keyword) {
                previousKeyword = $0.keyword
            }
        }
    }

    public func containsTags(_ tags: [String]) -> Bool {
        tags.contains { containsTag($0) }
    }

    func toJSON() -> [String: Any] {
        [
            "id": title.lowercased().replacingOccurrences(of: " ", with: "-"),
            "keyword": "Scenario",
            "type": "scenario",
            "name": title,
            "description": desc,
            "steps": []
        ]
    }
}
