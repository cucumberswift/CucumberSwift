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
        Cucumber.overrideStrictPendingSteps = false
    }

    func executeFeatures(callDefaultTestSuite: Bool = false) {
        if callDefaultTestSuite { _ = CucumberTest.defaultTestSuite }
        let suite = XCTestSuite(name: "Dummy")
        CucumberTest.generateAlltests(suite)

        var tests = [XCTestCase]()
        Cucumber.enumerateTestsCases(&tests, suite)
        tests.forEach { $0.invokeTest() }
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
