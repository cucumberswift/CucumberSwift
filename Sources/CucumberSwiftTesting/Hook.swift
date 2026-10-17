//
//  Hook.swift
//  CucumberSwiftTesting
//
// Hooks run on the main actor, in order of `priority`, lowest first, then those without one in the order
// they were added, as in CucumberSwift. A thrown error fails the test at the hook's own line, as in CucumberSwift.

import Foundation
import Testing

/// Runs once before a feature's first scenario, with the feature.
@MainActor
public func BeforeFeature(
    priority: UInt? = nil,
    file: StaticString = #filePath,
    line: UInt = #line,
    closure: @escaping @MainActor (Feature) async throws -> Void
) {
    Cucumber.shared.beforeFeatureHooks.append(Hook(priority: priority, file: file, line: line, body: closure))
}

/// Runs once after a feature's last scenario, whether or not they passed, with the feature.
@MainActor
public func AfterFeature(
    priority: UInt? = nil,
    file: StaticString = #filePath,
    line: UInt = #line,
    closure: @escaping @MainActor (Feature) async throws -> Void
) {
    Cucumber.shared.afterFeatureHooks.append(Hook(priority: priority, file: file, line: line, body: closure))
}

/// Runs before each scenario.
@MainActor
public func BeforeScenario(
    priority: UInt? = nil,
    file: StaticString = #filePath,
    line: UInt = #line,
    closure: @escaping @MainActor (Scenario) async throws -> Void
) {
    Cucumber.shared.beforeScenarioHooks.append(Hook(priority: priority, file: file, line: line, body: closure))
}

/// Runs after each scenario, whether or not it passed.
@MainActor
public func AfterScenario(
    priority: UInt? = nil,
    file: StaticString = #filePath,
    line: UInt = #line,
    closure: @escaping @MainActor (Scenario) async throws -> Void
) {
    Cucumber.shared.afterScenarioHooks.append(Hook(priority: priority, file: file, line: line, body: closure))
}

/// Runs before each step that a step definition matches.
@MainActor
public func BeforeStep(
    priority: UInt? = nil,
    file: StaticString = #filePath,
    line: UInt = #line,
    closure: @escaping @MainActor (Step) async throws -> Void
) {
    Cucumber.shared.beforeStepHooks.append(Hook(priority: priority, file: file, line: line, body: closure))
}

/// Runs after each step that ran, whether or not it passed.
@MainActor
public func AfterStep(
    priority: UInt? = nil,
    file: StaticString = #filePath,
    line: UInt = #line,
    closure: @escaping @MainActor (Step) async throws -> Void
) {
    Cucumber.shared.afterStepHooks.append(Hook(priority: priority, file: file, line: line, body: closure))
}

// The hooks that existed before `file:` and `line:`, for code that uses them as values, such as
// `let register: (UInt?, @escaping @MainActor (Scenario) async throws -> Void) -> Void = BeforeScenario`:
// default arguments don't apply to a function used as a value. A call with a closure uses the hooks above.

@_disfavoredOverload
@MainActor
public func BeforeScenario(priority: UInt? = nil, closure: @escaping @MainActor (Scenario) async throws -> Void) {
    BeforeScenario(priority: priority, file: #filePath, line: #line, closure: closure)
}

@_disfavoredOverload
@MainActor
public func AfterScenario(priority: UInt? = nil, closure: @escaping @MainActor (Scenario) async throws -> Void) {
    AfterScenario(priority: priority, file: #filePath, line: #line, closure: closure)
}

@_disfavoredOverload
@MainActor
public func BeforeStep(priority: UInt? = nil, closure: @escaping @MainActor (Step) async throws -> Void) {
    BeforeStep(priority: priority, file: #filePath, line: #line, closure: closure)
}

@_disfavoredOverload
@MainActor
public func AfterStep(priority: UInt? = nil, closure: @escaping @MainActor (Step) async throws -> Void) {
    AfterStep(priority: priority, file: #filePath, line: #line, closure: closure)
}

struct Hook<Argument> {
    let priority: UInt?
    /// Where the hook is written, which is where it fails when it throws, as with CucumberSwift.
    let file: StaticString
    let line: UInt
    let body: @MainActor (Argument) async throws -> Void

    var sourceLocation: SourceLocation {
        let path = "\(file)"
        let components = path.split(separator: "/").suffix(2)
        let fileID = components.count == 2 ? components.joined(separator: "/") : "Hooks/\(components.joined())"
        return SourceLocation(fileID: fileID, filePath: path, line: max(Int(line), 1), column: 1)
    }
}

extension Array {
    /// Hooks with a priority first, lowest first, then the others, each group in the order it was added,
    /// or that whole order reversed, as `reverseOrderForAfterHooks` asks for the after hooks.
    func inPriorityOrder<Argument>(reversed: Bool = false) -> [Hook<Argument>] where Element == Hook<Argument> {
        let ordered = enumerated()
            .sorted { lhs, rhs in
                switch (lhs.element.priority, rhs.element.priority) {
                    case let (l?, r?): return l == r ? lhs.offset < rhs.offset : l < r
                    case (_?, nil): return true
                    case (nil, _?): return false
                    case (nil, nil): return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
        return reversed ? ordered.reversed() : ordered
    }
}
