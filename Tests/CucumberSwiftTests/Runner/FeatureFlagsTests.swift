//
//  FeatureFlagsTests.swift
//  CucumberSwiftTests
//
//  Each feature flag is a static variable on Cucumber and an environment variable. The static
//  variable wins, then the environment variable, then the flag's default (#59).
//

import Foundation
import XCTest
@testable import CucumberSwift

class FeatureFlagsTests: XCTestCase {
    private static let variables = [
        "CUCUMBER_READABLE_TEST_NAMES",
        "CUCUMBER_ONE_TEST_PER_SCENARIO",
        "CUCUMBER_GENERATE_REGEX_LITERALS",
        "CUCUMBER_PARALLEL_TESTING"
    ]

    private static func resetFlags() {
        Cucumber.readableTestNames = nil
        Cucumber.oneTestPerScenario = nil
        Cucumber.generateRegexLiterals = nil
        Cucumber.parallelTesting = nil
        variables.forEach { Cucumber.shared.environment[$0] = nil }
    }

    override func setUpWithError() throws {
        Self.resetFlags()
        addTeardownBlock { Self.resetFlags() }
    }

    func testReadableTestNamesAreOnByDefault() {
        XCTAssertTrue(FeatureFlags.isReadableTestNames)
    }

    func testOneTestPerScenarioIsOffByDefault() {
        XCTAssertFalse(FeatureFlags.isOneTestPerScenario)
    }

    func testRegexLiteralStepDefinitionsAreOffByDefault() {
        XCTAssertFalse(FeatureFlags.isGenerateRegexLiterals)
    }

    func testParallelTestingIsOffByDefault() {
        XCTAssertFalse(FeatureFlags.isParallelTesting)
    }

    func testTheEnvironmentVariableOverridesTheDefault() {
        Cucumber.shared.environment["CUCUMBER_READABLE_TEST_NAMES"] = "NO"
        Cucumber.shared.environment["CUCUMBER_ONE_TEST_PER_SCENARIO"] = "YES"
        Cucumber.shared.environment["CUCUMBER_GENERATE_REGEX_LITERALS"] = "YES"
        Cucumber.shared.environment["CUCUMBER_PARALLEL_TESTING"] = "YES"

        XCTAssertFalse(FeatureFlags.isReadableTestNames)
        XCTAssertTrue(FeatureFlags.isOneTestPerScenario)
        XCTAssertTrue(FeatureFlags.isGenerateRegexLiterals)
        XCTAssertTrue(FeatureFlags.isParallelTesting)
    }

    func testTheStaticVariableOverridesTheEnvironmentVariable() {
        Cucumber.shared.environment["CUCUMBER_READABLE_TEST_NAMES"] = "NO"
        Cucumber.shared.environment["CUCUMBER_ONE_TEST_PER_SCENARIO"] = "YES"
        Cucumber.shared.environment["CUCUMBER_GENERATE_REGEX_LITERALS"] = "YES"
        Cucumber.readableTestNames = true
        Cucumber.oneTestPerScenario = false
        Cucumber.generateRegexLiterals = false
        Cucumber.shared.environment["CUCUMBER_PARALLEL_TESTING"] = "YES"
        Cucumber.parallelTesting = false

        XCTAssertTrue(FeatureFlags.isReadableTestNames)
        XCTAssertFalse(FeatureFlags.isOneTestPerScenario)
        XCTAssertFalse(FeatureFlags.isGenerateRegexLiterals)
        XCTAssertFalse(FeatureFlags.isParallelTesting)
    }

    func testAnUnknownEnvironmentValueLeavesTheDefault() {
        Cucumber.shared.environment["CUCUMBER_READABLE_TEST_NAMES"] = "maybe"
        Cucumber.shared.environment["CUCUMBER_ONE_TEST_PER_SCENARIO"] = "maybe"
        Cucumber.shared.environment["CUCUMBER_GENERATE_REGEX_LITERALS"] = "maybe"

        XCTAssertTrue(FeatureFlags.isReadableTestNames)
        XCTAssertFalse(FeatureFlags.isOneTestPerScenario)
        XCTAssertFalse(FeatureFlags.isGenerateRegexLiterals)
    }

    func testBooleanValuesInAnyCase() {
        ["YES", "yes", "True", "1", " 1 "].forEach { XCTAssertEqual(FeatureFlags.bool($0), true, $0) }
        ["NO", "no", "False", "0"].forEach { XCTAssertEqual(FeatureFlags.bool($0), false, $0) }
        ["", "maybe", "2"].forEach { XCTAssertNil(FeatureFlags.bool($0), $0) }
        XCTAssertNil(FeatureFlags.bool(nil))
    }
}
