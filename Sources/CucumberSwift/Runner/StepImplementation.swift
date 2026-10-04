//
//  StepImplementation.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/25/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

@preconcurrency @MainActor @objc public protocol StepImplementation {
    func setupSteps()
    var bundle: Bundle { get }
    @available(*, unavailable, renamed: "shouldRunWith(scenario:tags:)")
    @objc optional func shouldRunWith(tags: [String]) -> Bool
    @objc optional func shouldRunWith(scenario: Scenario?, tags: [String]) -> Bool
    @objc optional var continueTestingAfterFailure: Bool { get }
    @objc optional var reverseOrderForAfterHooks: Bool { get }
    /// How many seconds an async step or hook may run before it fails. Defaults to 60.
    @objc optional var asyncStepTimeout: TimeInterval { get }
    /// Whether CucumberSwift prints each feature, scenario and step, with its result and duration, as
    /// it runs. Defaults to `false`. Setting the `CUCUMBER_VERBOSE` environment variable to `1` or
    /// `true` turns it on without a code change.
    @objc optional var verbose: Bool { get }
    /// How the step definitions CucumberSwift generates for undefined steps write their regex literals,
    /// when ``Cucumber/generateRegexLiterals`` asks for regex literals rather than Cucumber Expressions.
    /// The default, ``RegexLiteralStyle/extendedDelimiter``, compiles in any test target.
    @objc optional var regexLiteralStyle: RegexLiteralStyle { get }
}
