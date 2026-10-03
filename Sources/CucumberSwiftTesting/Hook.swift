//
//  Hook.swift
//  CucumberSwiftTesting
//
// Hooks run on the main actor, in order of `priority`, lowest first, then those without one in the order
// they were added, as in CucumberSwift. A thrown error fails the scenario.

import Foundation

/// Runs before each scenario.
@MainActor
public func BeforeScenario(priority: UInt? = nil, closure: @escaping @MainActor (Scenario) async throws -> Void) {
    Cucumber.shared.beforeScenarioHooks.append(Hook(priority: priority, body: closure))
}

/// Runs after each scenario, whether or not it passed.
@MainActor
public func AfterScenario(priority: UInt? = nil, closure: @escaping @MainActor (Scenario) async throws -> Void) {
    Cucumber.shared.afterScenarioHooks.append(Hook(priority: priority, body: closure))
}

/// Runs before each step that a step definition matches.
@MainActor
public func BeforeStep(priority: UInt? = nil, closure: @escaping @MainActor (Step) async throws -> Void) {
    Cucumber.shared.beforeStepHooks.append(Hook(priority: priority, body: closure))
}

/// Runs after each step that ran, whether or not it passed.
@MainActor
public func AfterStep(priority: UInt? = nil, closure: @escaping @MainActor (Step) async throws -> Void) {
    Cucumber.shared.afterStepHooks.append(Hook(priority: priority, body: closure))
}

struct Hook<Argument> {
    let priority: UInt?
    let body: @MainActor (Argument) async throws -> Void
}

extension Array {
    /// Hooks with a priority first, lowest first, then the others, each group in the order it was added.
    func inPriorityOrder<Argument>() -> [Hook<Argument>] where Element == Hook<Argument> {
        enumerated()
            .sorted { lhs, rhs in
                switch (lhs.element.priority, rhs.element.priority) {
                    case let (l?, r?): return l == r ? lhs.offset < rhs.offset : l < r
                    case (_?, nil): return true
                    case (nil, _?): return false
                    case (nil, nil): return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }
}
