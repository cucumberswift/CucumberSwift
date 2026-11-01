//
//  Scenario.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 4/7/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

public class Scenario: NSObject, Taggable, Positionable {
    public private(set)  var title = ""
    public internal(set)  var tags = [String]()
    public internal(set)  var steps = [Step]()
    public internal(set) var desc: String = ""
    public internal(set) var feature: Feature?
    public private(set)  var location: Lexer.Position
    public private(set)  var endLocation: Lexer.Position
    internal var startDate = Date()
    let internalState = ScenarioState()
    /// The Rule the scenario is in, if it is in one, which the coverage scores score on its own.
    var rule: ScenarioRule?
    /// How many of ``steps`` are its Background's: its feature's, then its Rule's. The redundancy score
    /// leaves out the code they run.
    var backgroundStepCount = 0

    init(with node: AST.ScenarioNode, tags: [String], stepNodes: [AST.StepNode]) {
        location = node.tokens.first?.position ?? .start
        endLocation = .start
        desc = ""
        super.init()
        let header = NodeHeader(node.tokens)
        title = header.title
        desc = header.description
        self.tags = tags + header.tags
        steps ?= node.children.compactMap { $0 as? AST.StepNode }.map { Step(with: $0) }
        steps.insert(contentsOf: stepNodes.map { Step(with: $0) }, at: 0)
        backgroundStepCount = stepNodes.count
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
        let continuedKeywords = Step.Keyword.continuedKeywords(steps.map(\.keyword))
        for (step, continued) in zip(steps, continuedKeywords) {
            step.scenario = self
            if let continued {
                try? step.addPrimaryKeyword(continued)
            }
        }
    }

    /// The running scenario's own value of type `Value`, such as the basket its steps fill in: call it from
    /// any step or scenario hook, with no scenario to pass. `make` runs the first time any step or hook of
    /// this scenario asks for a `Value`, and every later call, from any step or hook of this scenario,
    /// gets the same object. Another scenario has a value of its own, so scenarios that run at the same
    /// time don't share it. The value is released when the scenario is over.
    ///
    /// ```swift
    /// enum World {
    ///     static var basket: Basket { Scenario.state(Basket.init) }
    /// }
    ///
    /// Given("the basket has {int} cukes") { match, _ in
    ///     World.basket.cukes = try match.first(\.int)
    /// }
    /// ```
    ///
    /// `Value` is a class so that what one step changes, the next sees. Different types are different
    /// values, so one scenario can have a `Basket` and a `Beach`. Called outside a step or a scenario hook,
    /// such as from a feature hook or a task a step left running, it records a failure and returns a new
    /// value that no scenario keeps.
    public static func state<Value: AnyObject>(_ make: () -> Value) -> Value {
        guard let scenario = Cucumber.shared.currentStep?.scenario else {
            XCTFail("Scenario.state(_:) needs a running scenario: call it from a step or a scenario hook.")
            return make()
        }
        return scenario.internalState.value(make)
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

extension ScenarioRule {
    init(_ node: AST.RuleNode) {
        self.init(title: NodeHeader(node.tokens).title, line: node.keywordLine)
    }
}
