//
//  CucumberExtensions.swift
//  CucumberSwiftTests
//
//  Created by Tyler Thompson on 3/2/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest
@testable import CucumberSwift

extension Cucumber {
    func reset() {
        Cucumber.shouldRunWith = { _, _ in true }
        Gherkin.errors.removeAll()
        RegularExpression.errors.removeAll()
        DuplicateStepDefinition.reset()
        features.removeAll()
        beforeFeatureHooks.removeAll()
        beforeScenarioHooks.removeAll()
        beforeStepHooks.removeAll()
        afterFeatureHooks.removeAll()
        afterScenarioHooks.removeAll()
        afterStepHooks.removeAll()
        environment["CUCUMBER_TAGS"] = nil
        hookedFeatures.removeAll()
        hookedScenarios.removeAll()
    }

    /// Runs every step's test. Many of these tests define only the steps they look at, so a step with no
    /// step definition, which fails its own test (#262), is an expected failure here, and nothing else is.
    func executeFeatures(callDefaultTestSuite: Bool = false) {
        if callDefaultTestSuite { _ = CucumberTest.defaultTestSuite }
        let suite = XCTestSuite(name: "Dummy")
        CucumberTest.generateAlltests(suite)

        var tests = [XCTestCase]()
        Cucumber.enumerateTestsCases(&tests, suite)
        guard #available(iOS 14.0, macOS 11.0, tvOS 14.0, *) else {
            tests.forEach { $0.invokeTest() }
            return
        }
        let options = XCTExpectedFailure.Options()
        options.isStrict = false
        options.issueMatcher = { $0.compactDescription.hasPrefix("No CucumberSwift expression found that matches this step.") }
        XCTExpectFailure("A step with no step definition", options: options) {
            tests.forEach { $0.invokeTest() }
        }
    }

    private static func enumerateTestsCases(_ tests: inout [XCTestCase], _ suite: XCTestSuite) {
        suite.tests.forEach {
            if let testCase = $0 as? XCTestCase {
                tests.append(testCase)
            } else if let suite = $0 as? XCTestSuite {
                enumerateTestsCases(&tests, suite)
            }
        }
    }
}
