//
//  BackgroundDSL.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 7/25/20.
//  Copyright © 2020 Tyler Thompson. All rights reserved.
//

import Foundation

public struct Background: ScenarioDSL {
    // intentionally blank because we do not want Backgrounds counted like other Scenarios
    public var scenarios: [Scenario] { [] }
    var steps: [StepDSL]

    @MainActor
    public init(@StepBuilder _ content: () -> [StepDSL]) {
        steps = content()
    }
    @MainActor
    public init(@StepBuilder _ content: () -> StepDSL) {
        steps = [content()]
    }
}
