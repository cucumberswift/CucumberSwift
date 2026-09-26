//
//  ScenarioBuilder.swift
//  CucumberSwift
//
//  Created by thompsty on 7/23/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//

import Foundation

@resultBuilder
public enum ScenarioBuilder {
    @MainActor
    public static func buildBlock(_ items: ScenarioDSL...) -> [ScenarioDSL] {
        let (backgroundSteps, scenarioDSLs) = items.reduce(into: ([StepDSL](), [ScenarioDSL]())) { res, scenarioDSL in
            if let background = scenarioDSL as? Background {
                res.0.append(contentsOf: background.steps)
            } else {
                res.1.append(scenarioDSL)
            }
        }
        let scenarios = scenarioDSLs.flatMap { $0.scenarios }
        scenarios.forEach {
            $0.steps.insert(contentsOf: backgroundSteps, at: 0)
        }
        return scenarios + scenarioDSLs.compactMap { $0 as? Description }
    }
}
