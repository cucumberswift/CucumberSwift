//
//  RuleDSL.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 7/25/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//

import Foundation

public struct Rule: ScenarioDSL {
    public let scenarios: [Scenario]

    /// A rule's tags are its scenarios', before their own, as Gherkin has them inherit a rule's tags. The title
    /// and position are not used, as with a rule in a feature file.
    private static func addTags(_ tags: [String], to scenarios: [Scenario]) {
        scenarios.forEach { $0.tags = tags + $0.tags }
    }

    public init(_ title: String,
                tags: [String] = [],
                line: UInt = #line,
                column: UInt = #column,
                @ScenarioBuilder _ content: () -> [ScenarioDSL]) {
        scenarios = content().flatMap { $0.scenarios }
        Self.addTags(tags, to: scenarios)
    }
    public init(_ title: String,
                tags: [String] = [],
                line: UInt = #line,
                column: UInt = #column,
                @ScenarioBuilder _ content: () -> ScenarioDSL) {
        scenarios = content().scenarios
        Self.addTags(tags, to: scenarios)
    }
}
