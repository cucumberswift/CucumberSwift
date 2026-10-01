//
//  StepImplementation.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/25/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

/// How a generated step definition writes its regular expression literal.
///
/// Which form compiles is a setting of the test target the code is pasted into, not of CucumberSwift,
/// so CucumberSwift can't detect it. Both need Swift 5.7 or later.
@objc public enum RegexLiteralStyle: Int {
    /// `#/^…$/#`. Compiles in every language mode, with no compiler setting. The default.
    case extendedDelimiter
    /// `/^…$/`. Needs the Swift 6 language mode or the `BareSlashRegexLiterals` feature. Xcode
    /// turns that feature on by default ("Enable Bare Slash Regex Literals"); Swift Package Manager
    /// targets in the Swift 5 language mode need
    /// `swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiterals")]`.
    case bareSlash
}

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
    /// How the step definitions CucumberSwift generates for undefined steps write their regular
    /// expressions. The default, ``RegexLiteralStyle/extendedDelimiter``, compiles in any test target.
    @objc optional var regexLiteralStyle: RegexLiteralStyle { get }
    /// Whether the tests CucumberSwift generates are named with the feature, scenario and step text
    /// as written, such as `Checkout|Pay with a gift card` and `Step002_Then the total is 99`, rather
    /// than in camel case, such as `Checkout|PayWithAGiftCard` and `Step002_ThenTheTotalIs99`.
    /// Defaults to `false`, because tools that parse `xcodebuild`'s output may expect test names
    /// without spaces.
    @objc optional var readableTestNames: Bool { get }
    /// Whether each scenario is one test, named after its feature and scenario, whose steps run in
    /// order within it, rather than a test class with a test for each step. Xcode's test navigator can
    /// then run a single scenario. Defaults to `false`: a test for each step. The environment variable
    /// `CUCUMBER_ONE_TEST_PER_SCENARIO`, set to `YES` or `NO` in a scheme or test plan, overrides it.
    @objc optional var oneTestPerScenario: Bool { get }
}
