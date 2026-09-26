//
//  StepImplementation.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/25/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

@objc public protocol StepImplementation {
    func setupSteps()
    var bundle: Bundle { get }
    @available(*, unavailable, renamed: "shouldRunWith(scenario:tags:)")
    @objc optional func shouldRunWith(tags: [String]) -> Bool
    @objc optional func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool
    @objc optional var continueTestingAfterFailure: Bool { get }
    @objc optional var reverseOrderForAfterHooks: Bool { get }

    /// When `true`, a parsed step that has no attached definition (`Step.canExecute == false`)
    /// fails its own generated XCTest method with a clear message instead of silently reporting
    /// `passed`. Defaults to `false` to preserve existing behavior, where unmatched steps are
    /// only surfaced in aggregate via `testGherkin`.
    @objc optional var strictPendingSteps: Bool { get }
}
