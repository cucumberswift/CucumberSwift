//
//  Globals.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/25/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

// MARK: Hooks
public func BeforeFeature(priority: UInt? = nil, closure: @escaping ((Feature) -> Void)) {
    Cucumber.shared.beforeFeatureHooks.append(.init(priority: priority, hook: closure))
}
public func AfterFeature(priority: UInt? = nil, closure: @escaping ((Feature) -> Void)) {
    Cucumber.shared.afterFeatureHooks.append(.init(priority: priority, hook: closure))
}
public func BeforeScenario(priority: UInt? = nil, closure: @escaping ((Scenario) -> Void)) {
    Cucumber.shared.beforeScenarioHooks.append(.init(priority: priority, hook: closure))
}
public func AfterScenario(priority: UInt? = nil, closure: @escaping ((Scenario) -> Void)) {
    Cucumber.shared.afterScenarioHooks.append(.init(priority: priority, hook: closure))
}
public func BeforeStep(priority: UInt? = nil, closure: @escaping ((Step) -> Void)) {
    Cucumber.shared.beforeStepHooks.append(.init(priority: priority, hook: closure))
}
public func AfterStep(priority: UInt? = nil, closure: @escaping ((Step) -> Void)) {
    Cucumber.shared.afterStepHooks.append(.init(priority: priority, hook: closure))
}
// MARK: Async hooks
// A closure runs on the main actor, and CucumberSwift waits for it to finish before going on. A thrown error fails the test.
public func BeforeFeature(priority: UInt? = nil,
                          file: StaticString = #filePath,
                          line: UInt = #line,
                          closure: @escaping @MainActor (Feature) async throws -> Void) {
    Cucumber.shared.beforeFeatureHooks.append(.init(priority: priority, hook: AsyncStepRunner.blockingHook(closure, file: file, line: line)))
}
public func AfterFeature(priority: UInt? = nil,
                         file: StaticString = #filePath,
                         line: UInt = #line,
                         closure: @escaping @MainActor (Feature) async throws -> Void) {
    Cucumber.shared.afterFeatureHooks.append(.init(priority: priority, hook: AsyncStepRunner.blockingHook(closure, file: file, line: line)))
}
public func BeforeScenario(priority: UInt? = nil,
                           file: StaticString = #filePath,
                           line: UInt = #line,
                           closure: @escaping @MainActor (Scenario) async throws -> Void) {
    Cucumber.shared.beforeScenarioHooks.append(.init(priority: priority, hook: AsyncStepRunner.blockingHook(closure, file: file, line: line)))
}
public func AfterScenario(priority: UInt? = nil,
                          file: StaticString = #filePath,
                          line: UInt = #line,
                          closure: @escaping @MainActor (Scenario) async throws -> Void) {
    Cucumber.shared.afterScenarioHooks.append(.init(priority: priority, hook: AsyncStepRunner.blockingHook(closure, file: file, line: line)))
}
public func BeforeStep(priority: UInt? = nil,
                       file: StaticString = #filePath,
                       line: UInt = #line,
                       closure: @escaping @MainActor (Step) async throws -> Void) {
    Cucumber.shared.beforeStepHooks.append(.init(priority: priority, hook: AsyncStepRunner.blockingHook(closure, file: file, line: line)))
}
public func AfterStep(priority: UInt? = nil,
                      file: StaticString = #filePath,
                      line: UInt = #line,
                      closure: @escaping @MainActor (Step) async throws -> Void) {
    Cucumber.shared.afterStepHooks.append(.init(priority: priority, hook: AsyncStepRunner.blockingHook(closure, file: file, line: line)))
}

// Execute a step matching the given step definition
public func ExecuteFirstStep(keyword: Step.Keyword? = nil, matching: String) {
    Cucumber.shared.executeFirstStep(keyword: keyword, matching: matching)
}
// From inside an async step or hook, execute a step matching the given step definition and wait for it
@MainActor
public func ExecuteFirstStep(keyword: Step.Keyword? = nil, matching: String) async {
    await Cucumber.shared.executeFirstStep(keyword: keyword, matching: matching)
}

// MARK: Attachments
/// Adds an attachment, such as a screenshot, a log or a file, to the test that is running.
///
/// Call it from any hook or step, where there is no `XCTestCase` to call `add(_:)` on. Set `lifetime` to
/// `.keepAlways` to keep the attachment when the test passes, and `name` to label it. The attachment appears
/// under an "Attachment" activity on the current step's test, so one added in `AfterScenario` is on the
/// scenario's last step.
public func Attach(_ attachment: XCTAttachment) {
    attach(attachment) { name, block in
        XCTContext.runActivity(named: name, block: block)
    }
}

/// `runActivity` is a parameter so a test can see what gets attached.
func attach(_ attachment: XCTAttachment, runActivity: (String, (XCTActivity) -> Void) -> Void) {
    runActivity(attachment.name ?? "Attachment") { activity in
        activity.add(attachment)
    }
}
