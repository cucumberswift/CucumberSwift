//
//  Globals.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/25/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

// MARK: Hooks
@MainActor
public func BeforeFeature(priority: UInt? = nil, closure: @escaping ((Feature) -> Void)) {
    Cucumber.shared.beforeFeatureHooks.append(.init(priority: priority, hook: closure))
}
@MainActor
public func AfterFeature(priority: UInt? = nil, closure: @escaping ((Feature) -> Void)) {
    Cucumber.shared.afterFeatureHooks.append(.init(priority: priority, hook: closure))
}
@MainActor
public func BeforeScenario(priority: UInt? = nil, closure: @escaping ((Scenario) -> Void)) {
    Cucumber.shared.beforeScenarioHooks.append(.init(priority: priority, hook: closure))
}
@MainActor
public func AfterScenario(priority: UInt? = nil, closure: @escaping ((Scenario) -> Void)) {
    Cucumber.shared.afterScenarioHooks.append(.init(priority: priority, hook: closure))
}
@MainActor
public func BeforeStep(priority: UInt? = nil, closure: @escaping ((Step) -> Void)) {
    Cucumber.shared.beforeStepHooks.append(.init(priority: priority, hook: closure))
}
@MainActor
public func AfterStep(priority: UInt? = nil, closure: @escaping ((Step) -> Void)) {
    Cucumber.shared.afterStepHooks.append(.init(priority: priority, hook: closure))
}
// Execute a step matching the given step definition
@MainActor
public func ExecuteFirstStep(keyword: Step.Keyword? = nil, matching: String) {
    Cucumber.shared.executeFirstStep(keyword: keyword, matching: matching)
}
