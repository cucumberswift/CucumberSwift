//
//  StepBuilder.swift
//  CucumberSwift
//
//  Created by thompsty on 7/23/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//

import Foundation
@resultBuilder
public enum StepBuilder {
    /// The steps, without any step definition written among them, which `testGherkin()` reports instead: a DSL
    /// step runs its own code, and a step definition, which has none, belongs outside the feature.
    public static func buildBlock(_ items: StepDSL?...) -> [StepDSL] {
        let steps = items.compactMap { $0 }
        for step in steps where !step.canExecute {
            MisplacedStepDefinition.record(file: step.sourceFile, line: step.sourceLine)
        }
        let placed = steps.filter(\.canExecute)
        MisplacedStepDefinition.placed(placed)
        return placed
    }
}
